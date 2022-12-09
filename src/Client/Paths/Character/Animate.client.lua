local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local pose = "Standing"

local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function()
    return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop")
end)
local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue

local userEmoteToRunThresholdChange
do
    local success, value = pcall(function()
        return UserSettings():IsUserFeatureEnabled("UserEmoteToRunThresholdChange")
    end)
    userEmoteToRunThresholdChange = success and value
end

local userPlayEmoteByIdAnimTrackReturn
do
    local success, value = pcall(function()
        return UserSettings():IsUserFeatureEnabled("UserPlayEmoteByIdAnimTrackReturn2")
    end)
    userPlayEmoteByIdAnimTrackReturn = success and value
end

local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
local HumanoidHipHeight = 2

local EMOTE_TRANSITION_TIME = 0.1

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0

local runAnimTrack = nil
local runAnimKeyframeHandler = nil

local PreloadedAnims = {}

local animTable = {}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
-- Emotes: wave, point, dance, dance2, dance3, laugh, cheer
local emoteNames = { Wave = false, Point = false, Cheer = false }

math.randomseed(tick())

function configureAnimationSet(name, fileList)
    if animTable[name] ~= nil then
        for _, connection in pairs(animTable[name].connections) do
            connection:disconnect()
        end
    end
    animTable[name] = {}
    animTable[name].count = 0
    animTable[name].totalWeight = 0
    animTable[name].connections = {}

    -- fallback to defaults
    if animTable[name].count <= 0 then
        for idx, anim in pairs(fileList) do
            animTable[name][idx] = {}
            animTable[name][idx].anim = Instance.new("Animation")
            animTable[name][idx].anim.Name = name
            animTable[name][idx].anim.AnimationId = anim.Id
            animTable[name][idx].weight = anim.Weight
            animTable[name].count = animTable[name].count + 1
            animTable[name].totalWeight = animTable[name].totalWeight + anim.Weight
        end
    end

    -- preload anims
    for i, animType in pairs(animTable) do
        for idx = 1, animType.count, 1 do
            if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
                Humanoid:LoadAnimation(animType[idx].anim)
                PreloadedAnims[animType[idx].anim.AnimationId] = true
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------
-- Clear any existing animation tracks
-- Fixes issue with characters that are moved in and out of the Workspace accumulating tracks
local animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
if animator then
    local animTracks = animator:GetPlayingAnimationTracks()
    for _, track in ipairs(animTracks) do
        track:Stop(0)
        track:Destroy()
    end
end

for name, fileList in pairs(CharacterConstants.Animations) do
    configureAnimationSet(name, fileList)
end

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.31

local toolTransitionTime = 0.1
local fallTransitionTime = 0.2

local currentlyPlayingEmote = false

-- functions

function stopAllAnimations()
    local oldAnim = currentAnim

    -- return to idle if finishing an emote
    if emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false then
        oldAnim = "idle"
    end

    if currentlyPlayingEmote then
        oldAnim = "idle"
        currentlyPlayingEmote = false
    end

    currentAnim = ""
    currentAnimInstance = nil
    if currentAnimKeyframeHandler ~= nil then
        currentAnimKeyframeHandler:disconnect()
    end

    if currentAnimTrack ~= nil then
        currentAnimTrack:Stop()
        currentAnimTrack:Destroy()
        currentAnimTrack = nil
    end

    -- clean up walk if there is one
    if runAnimKeyframeHandler ~= nil then
        runAnimKeyframeHandler:disconnect()
    end

    if runAnimTrack ~= nil then
        runAnimTrack:Stop()
        runAnimTrack:Destroy()
        runAnimTrack = nil
    end

    return oldAnim
end

function getHeightScale()
    if Humanoid then
        if not Humanoid.AutomaticScalingEnabled then
            return 1
        end

        local scale = Humanoid.HipHeight / HumanoidHipHeight
        if AnimationSpeedDampeningObject == nil then
            AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
        end
        if AnimationSpeedDampeningObject ~= nil then
            scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
        end
        return scale
    end
    return 1
end

local function rootMotionCompensation(speed)
    local speedScaled = speed * 1.25
    local heightScale = getHeightScale()
    local runSpeed = speedScaled / heightScale
    return runSpeed
end

local smallButNotZero = 0.0001
local function setRunSpeed(speed)
    local normalizedWalkSpeed = 0.5 -- established empirically using current `913402848` walk animation
    local normalizedRunSpeed = 1
    local runSpeed = rootMotionCompensation(speed)

    local walkAnimationWeight = smallButNotZero
    local runAnimationWeight = smallButNotZero
    local walkAnimationTimewarp
    local runAnimationTimerwarp = runSpeed / normalizedRunSpeed

    if runSpeed <= normalizedWalkSpeed then
        walkAnimationWeight = 1
    elseif runSpeed < normalizedRunSpeed then
        local fadeInRun = (runSpeed - normalizedWalkSpeed) / (normalizedRunSpeed - normalizedWalkSpeed)
        walkAnimationWeight = 1 - fadeInRun
        runAnimationWeight = fadeInRun
        walkAnimationTimewarp = 1
        runAnimationTimerwarp = 1
    else
        runAnimationWeight = 1
    end
    currentAnimTrack:AdjustWeight(walkAnimationWeight)
    runAnimTrack:AdjustWeight(runAnimationWeight)
    currentAnimTrack:AdjustSpeed(walkAnimationTimewarp)
    runAnimTrack:AdjustSpeed(runAnimationTimerwarp)
end

function setAnimationSpeed(speed)
    if currentAnim == "walk" then
        setRunSpeed(speed)
    else
        if speed ~= currentAnimSpeed then
            currentAnimSpeed = speed
            currentAnimTrack:AdjustSpeed(currentAnimSpeed)
        end
    end
end

function keyFrameReachedFunc(frameName)
    if frameName == "End" then
        if currentAnim == "walk" then
            if userNoUpdateOnLoop == true then
                if runAnimTrack.Looped ~= true then
                    runAnimTrack.TimePosition = 0.0
                end
                if currentAnimTrack.Looped ~= true then
                    currentAnimTrack.TimePosition = 0.0
                end
            else
                runAnimTrack.TimePosition = 0.0
                currentAnimTrack.TimePosition = 0.0
            end
        else
            local repeatAnim = currentAnim
            -- return to idle if finishing an emote
            if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
                repeatAnim = "idle"
            end

            if currentlyPlayingEmote then
                if currentAnimTrack.Looped then
                    -- Allow the emote to loop
                    return
                end

                repeatAnim = "idle"
                currentlyPlayingEmote = false
            end

            local animSpeed = currentAnimSpeed
            playAnimation(repeatAnim, 0.15, Humanoid)
            setAnimationSpeed(animSpeed)
        end
    end
end

function rollAnimation(animName)
    local roll = math.random(1, animTable[animName].totalWeight)
    local origRoll = roll
    local idx = 1
    while roll > animTable[animName][idx].weight do
        roll = roll - animTable[animName][idx].weight
        idx = idx + 1
    end
    return idx
end

local function switchToAnim(anim, animName, transitionTime, humanoid)
    -- switch animation
    if anim ~= currentAnimInstance then
        if currentAnimTrack ~= nil then
            currentAnimTrack:Stop(transitionTime)
            currentAnimTrack:Destroy()
        end

        if runAnimTrack ~= nil then
            runAnimTrack:Stop(transitionTime)
            runAnimTrack:Destroy()
            if userNoUpdateOnLoop == true then
                runAnimTrack = nil
            end
        end

        currentAnimSpeed = 1.0

        -- load it to the humanoid; get AnimationTrack
        currentAnimTrack = humanoid:LoadAnimation(anim)
        currentAnimTrack.Priority = Enum.AnimationPriority.Core

        -- play the animation
        currentAnimTrack:Play(transitionTime)
        currentAnim = animName
        currentAnimInstance = anim

        -- set up keyframe name triggers
        if currentAnimKeyframeHandler ~= nil then
            currentAnimKeyframeHandler:disconnect()
        end
        currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)

        -- check to see if we need to blend a walk/run animation
        if animName == "walk" then
            local runAnimName = "run"
            local runIdx = rollAnimation(runAnimName)

            runAnimTrack = humanoid:LoadAnimation(animTable[runAnimName][runIdx].anim)
            runAnimTrack.Priority = Enum.AnimationPriority.Core
            runAnimTrack:Play(transitionTime)

            if runAnimKeyframeHandler ~= nil then
                runAnimKeyframeHandler:disconnect()
            end
            runAnimKeyframeHandler = runAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)
        end
    end
end

function playAnimation(animName, transitionTime, humanoid)
    local idx = rollAnimation(animName)
    local anim = animTable[animName][idx].anim

    switchToAnim(anim, animName, transitionTime, humanoid)
    currentlyPlayingEmote = false
end

function playEmote(emoteAnim, transitionTime, humanoid)
    switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
    currentlyPlayingEmote = true
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
    if frameName == "End" then
        playToolAnimation(toolAnimName, 0.0, Humanoid)
    end
end

function playToolAnimation(animName, transitionTime, humanoid, priority)
    local idx = rollAnimation(animName)
    local anim = animTable[animName][idx].anim

    if toolAnimInstance ~= anim then
        if toolAnimTrack ~= nil then
            toolAnimTrack:Stop()
            toolAnimTrack:Destroy()
            transitionTime = 0
        end

        -- load it to the humanoid; get AnimationTrack
        toolAnimTrack = humanoid:LoadAnimation(anim)
        if priority then
            toolAnimTrack.Priority = priority
        end

        -- play the animation
        toolAnimTrack:Play(transitionTime)
        toolAnimName = animName
        toolAnimInstance = anim

        currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:Connect(toolKeyFrameReachedFunc)
    end
end

function stopToolAnimations()
    local oldAnim = toolAnimName

    if currentToolAnimKeyframeHandler ~= nil then
        currentToolAnimKeyframeHandler:disconnect()
    end

    toolAnimName = ""
    toolAnimInstance = nil
    if toolAnimTrack ~= nil then
        toolAnimTrack:Stop()
        toolAnimTrack:Destroy()
        toolAnimTrack = nil
    end

    return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- STATE CHANGE HANDLERS

function onRunning(speed)
    local movedDuringEmote = userEmoteToRunThresholdChange and currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
    local speedThreshold = movedDuringEmote and Humanoid.WalkSpeed or 0.75
    if speed > speedThreshold then
        local scale = 16.0
        playAnimation("Walk", 0.2, Humanoid)
        setAnimationSpeed(speed / scale)
        pose = "Running"
    else
        if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
            playAnimation("Idle", 0.2, Humanoid)
            pose = "Standing"
        end
    end
end

function onDied()
    pose = "Dead"
end

function onJumping()
    playAnimation("Jump", 0.1, Humanoid)
    jumpAnimTime = jumpAnimDuration
    pose = "Jumping"
end

function onClimbing(speed)
    local scale = 5.0
    playAnimation("Climb", 0.1, Humanoid)
    setAnimationSpeed(speed / scale)
    pose = "Climbing"
end

function onGettingUp()
    pose = "GettingUp"
end

function onFreeFall()
    if jumpAnimTime <= 0 then
        playAnimation("Fall", fallTransitionTime, Humanoid)
    end
    pose = "FreeFall"
end

function onFallingDown()
    pose = "FallingDown"
end

function onSeated()
    pose = "Seated"
end

function onPlatformStanding()
    pose = "PlatformStanding"
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

function onSwimming(speed)
    if speed > 1.00 then
        local scale = 10.0
        playAnimation("Swim", 0.4, Humanoid)
        setAnimationSpeed(speed / scale)
        pose = "Swimming"
    else
        playAnimation("SwimIdle", 0.4, Humanoid)
        pose = "Standing"
    end
end

function animateTool()
    if toolAnim == "None" then
        playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
        return
    end

    if toolAnim == "Slash" then
        playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
        return
    end

    if toolAnim == "Lunge" then
        playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
        return
    end
end

function getToolAnim(tool)
    for _, c in ipairs(tool:GetChildren()) do
        if c.Name == "toolanim" and c.className == "StringValue" then
            return c
        end
    end
    return nil
end

local lastTick = 0

function stepAnimate(currentTime)
    local amplitude = 1
    local frequency = 1
    local deltaTime = currentTime - lastTick
    lastTick = currentTime

    local climbFudge = 0
    local setAngles = false

    if jumpAnimTime > 0 then
        jumpAnimTime = jumpAnimTime - deltaTime
    end

    if pose == "FreeFall" and jumpAnimTime <= 0 then
        playAnimation("Fall", fallTransitionTime, Humanoid)
    elseif pose == "Seated" then
        playAnimation("Sit", 0.25, Humanoid)
        return
    elseif pose == "Running" then
        playAnimation("Walk", 0.2, Humanoid)
    elseif pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding" then
        stopAllAnimations()
        amplitude = 0.1
        frequency = 1
        setAngles = true
    end

    -- Tool Animation handling
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then
        local animStringValueObject = getToolAnim(tool)

        if animStringValueObject then
            toolAnim = animStringValueObject.Value
            -- message recieved, delete StringValue
            animStringValueObject.Parent = nil
            toolAnimTime = currentTime + 0.3
        end

        if currentTime > toolAnimTime then
            toolAnimTime = 0
            toolAnim = "None"
        end

        animateTool()
    else
        stopToolAnimations()
        toolAnim = "None"
        toolAnimInstance = nil
        toolAnimTime = 0
    end
end

-- Connect events
Humanoid.Died:Connect(onDied)
Humanoid.Running:Connect(onRunning)
Humanoid.Jumping:Connect(onJumping)
Humanoid.Climbing:Connect(onClimbing)
Humanoid.GettingUp:Connect(onGettingUp)
Humanoid.FreeFalling:Connect(onFreeFall)
Humanoid.FallingDown:Connect(onFallingDown)
Humanoid.Seated:Connect(onSeated)
Humanoid.PlatformStanding:Connect(onPlatformStanding)
Humanoid.Swimming:Connect(onSwimming)

if Character.Parent ~= nil then
    -- initialize to idle
    playAnimation("Idle", 0.1, Humanoid)
    pose = "Standing"
end

TextChatService.TextChatCommands.Emote.Triggered:Connect(function(_, message)
    local emote = ""
    if string.sub(message, 1, 3) == "/e " then
        emote = string.sub(message, 4)
    elseif string.sub(message, 1, 7) == "/emote " then
        emote = string.sub(message, 8)
    end

    emote = emote:lower()
    emote = emote:sub(1, 1):upper() .. emote:sub(2, #emote)

    if pose == "Standing" and emoteNames[emote] ~= nil then
        playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
    end
end)

-- loop to handle timed state transitions and tool animations
while Character.Parent ~= nil do
    local _, currentGameTime = wait(0.1)
    stepAnimate(currentGameTime)
end
