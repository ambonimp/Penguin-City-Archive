local EmotesScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local InputController = require(Paths.Client.Input.InputController)
local InputConstants = require(Paths.Client.Input.InputConstants)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)

local UP_VECTOR = Vector2.new(0, 1)
local TOTAL_SECTIONS = 8
local SECTION_1_ANGLE = 0 -- Middle of section 1 is at 0 deg via UP_VECTOR
local SECTION_WIDTH_DEGREES = 360 / TOTAL_SECTIONS
local SELECTION_ROTATION_OFFSET = -90
local SELECTION_ROTATION_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local VIEWPORT_ROTATION = CFrame.new(Vector3.new(0, 0, 0), Vector3.new(0, -0.2, -1))
local CREATE_ANIMATION_TRACKS_AFTER = 1
local PLACE_IN_VIEWPORT_AFTER = 2 -- Workspace -> Viewport delay, as I was getting error "Cannot load the AnimationClipProvider Service."

local uiStateMachine = UIController.getStateMachine()
local bootMaid = Maid.new()
local currentSection: number?
local playingAnimationTrack: AnimationTrack?
local playingAnimationTrackOnActualPlayerCharacter: AnimationTrack?
local animationTracksByEmoteName: { [string]: AnimationTrack } = {}

local screenGui: ScreenGui = Paths.UI.Emotes
local menuFrame: Frame = screenGui.EmotesMenu
local backgroundSelectionGradient: Frame = menuFrame.Main.EmotesWheel.Back.Background.BackgroundGradient.SelectionGradient
local innerSelectionLine: Frame = menuFrame.Main.EmotesWheel.Back.Background.Selection.SelectionEffect
local viewportFrame: ViewportFrame = menuFrame.Main.EmotesWheel.Back.Background.Middle.ViewportFrame

function EmotesScreen.Init()
    -- Register UIState
    do
        UIController.registerStateScreenCallbacks(UIConstants.States.Emotes, {
            Boot = EmotesScreen.boot,
            Shutdown = EmotesScreen.shutdown,
            Maximize = EmotesScreen.maximize,
            Minimize = EmotesScreen.minimize,
        })
    end

    -- Keybind to toggle
    do
        InputController.KeybindEnded:Connect(function(keybind: string, gameProcessedEvent: boolean)
            -- RETURN: Not a good event
            if not (keybind == "ToggleEmotes" and not gameProcessedEvent) then
                return
            end

            -- RETURN: Only run routine when we can see the HUD or see the Emotes screen
            if not (UIController.isStateMaximized(UIConstants.States.HUD) or UIController.isStateMaximized(UIConstants.States.Emotes)) then
                return
            end

            -- Toggle
            if uiStateMachine:HasState(UIConstants.States.Emotes) then
                uiStateMachine:Remove(UIConstants.States.Emotes)
            else
                uiStateMachine:Push(UIConstants.States.Emotes)
            end
        end)
    end

    -- UI Init
    do
        backgroundSelectionGradient.Visible = true
        innerSelectionLine.Visible = true
    end

    -- Viewport in the middle
    do
        -- Create a copy of our character
        local characterModel = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
        characterModel.Name = "EmotesCharacter"
        characterModel.Parent = game.Workspace

        -- Animations
        local humanoid: Humanoid = characterModel:WaitForChild("Humanoid")

        -- AnimationTracks
        for _, emoteName in pairs(CharacterConstants.EmoteNames) do
            local animation = CharacterConstants.Animations[emoteName][1]
            local animationId: string = animation.Id

            local animationInstance = Instance.new("Animation")
            animationInstance.Name = emoteName
            animationInstance.AnimationId = animationId
            animationInstance.Parent = humanoid

            -- Create track on new thread; was getting error "Cannot load the AnimationClipProvider Service."
            task.delay(CREATE_ANIMATION_TRACKS_AFTER, function()
                local animationTrack = humanoid:LoadAnimation(animationInstance) -- sorry not sorry
                animationTracksByEmoteName[emoteName] = animationTrack
            end)
        end

        -- Viewport
        task.delay(PLACE_IN_VIEWPORT_AFTER, function()
            CameraUtil.lookAtModelInViewport(viewportFrame, characterModel, {
                Rotation = VIEWPORT_ROTATION,
            })

            -- Need a world model for animations to work
            local worldModel = Instance.new("WorldModel")
            worldModel.Parent = viewportFrame
            characterModel.Parent = worldModel
        end)
    end
end

local function getSectionFromAngle(angleDegrees: number)
    local offsetAngle = (angleDegrees + SECTION_1_ANGLE + SECTION_WIDTH_DEGREES / 2) % 360
    local section = MathUtil.wrapAround(math.floor(offsetAngle / SECTION_WIDTH_DEGREES) + 1, TOTAL_SECTIONS)
    return section
end

local function getAngleFromSection(section: number)
    return (section - 1) * SECTION_WIDTH_DEGREES
end

local function getEmoteNameFromSection(section: number)
    local emoteName = CharacterConstants.EmoteNames[section]
    if not emoteName then
        error(("No emote for section %d"):format(section))
    end

    return emoteName
end

local function playAnimationForCurrentSection()
    -- ERROR: Not enough emote names!
    local emoteName = getEmoteNameFromSection(currentSection)

    -- ERROR: No track!
    local animationTrack = animationTracksByEmoteName[emoteName]
    if not animationTrack then
        error(("No AnimationTrack for emote %q"):format(emoteName))
    end

    -- Stop old track
    if playingAnimationTrack then
        playingAnimationTrack:Stop()
    end

    -- Play new track
    animationTrack:Play()

    -- Update Cache
    playingAnimationTrack = animationTrack
end

local function updateSection(newSection: number)
    -- Cache
    local oldSection = currentSection
    currentSection = newSection

    -- Selection Visuals
    do
        -- Modify the current Rotation value if we're crossing that 0deg/360deg border; we get unwanted snapping behaviour otherwise
        if oldSection == 1 and currentSection == TOTAL_SECTIONS then
            backgroundSelectionGradient.Rotation = backgroundSelectionGradient.Rotation + 360
            innerSelectionLine.Rotation = innerSelectionLine.Rotation + 360
        elseif oldSection == TOTAL_SECTIONS and currentSection == 1 then
            backgroundSelectionGradient.Rotation = backgroundSelectionGradient.Rotation - 360
            innerSelectionLine.Rotation = innerSelectionLine.Rotation - 360
        end

        local rotationValue = getAngleFromSection(currentSection) + SELECTION_ROTATION_OFFSET
        TweenUtil.tween(backgroundSelectionGradient, SELECTION_ROTATION_TWEEN_INFO, {
            Rotation = rotationValue,
        })
        TweenUtil.tween(innerSelectionLine, SELECTION_ROTATION_TWEEN_INFO, {
            Rotation = rotationValue,
        })
    end

    playAnimationForCurrentSection()
end

local function playAnimationForCurrentSectionOnActualPlayerCharacter()
    -- RETURN: No character!
    local character = Players.LocalPlayer.Character
    if not character then
        return
    end

    -- RETURN: No humanoid!
    local humanoid: Humanoid = character.Humanoid
    if not humanoid then
        return
    end

    -- RETURN: No animator!
    local animator = character.Humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    -- Stop old
    if playingAnimationTrackOnActualPlayerCharacter then
        playingAnimationTrackOnActualPlayerCharacter:Stop()
    end

    -- Play
    local emoteName = currentSection and getEmoteNameFromSection(currentSection)
    if emoteName then
        local animationEmote = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations[emoteName][1].Id })
        local useTrack = animator:LoadAnimation(animationEmote)
        useTrack:Play()

        playingAnimationTrackOnActualPlayerCharacter = useTrack

        -- Cleanup after
        task.delay(useTrack.Length, function()
            if playingAnimationTrackOnActualPlayerCharacter == useTrack then
                useTrack:Stop()
                useTrack:Destroy()
                playingAnimationTrackOnActualPlayerCharacter = nil
            end
        end)
    end
end

function EmotesScreen.boot()
    -- Frame update; detect what section we're hovering over
    bootMaid:GiveTask(RunService.RenderStepped:Connect(function()
        -- Calculate angle mouse is at in relation to center + up vector of the wheel
        local absoluteCenter = menuFrame.AbsolutePosition + menuFrame.AbsoluteSize / 2
        local mousePosition = InputController.getMouseLocation(false)

        local absoluteCenterToMousePosition = mousePosition - absoluteCenter
        local angle = VectorUtil.getVector2FullAngle(UP_VECTOR, -absoluteCenterToMousePosition)

        -- Calculate + update section
        local section = getSectionFromAngle(angle)
        if section ~= currentSection then
            updateSection(section)
        end
    end))

    -- Selection
    bootMaid:GiveTask(InputController.CursorUp:Connect(function()
        playAnimationForCurrentSectionOnActualPlayerCharacter()

        UIController.getStateMachine():Remove(UIConstants.States.Emotes)
    end))
end

function EmotesScreen.shutdown()
    bootMaid:Cleanup()

    currentSection = nil

    if playingAnimationTrack then
        playingAnimationTrack:Stop()
    end
    playingAnimationTrack = nil
end

function EmotesScreen.maximize()
    ScreenUtil.inDown(menuFrame)
    screenGui.Enabled = true
end

function EmotesScreen.minimize()
    ScreenUtil.outUp(menuFrame)
end

return EmotesScreen
