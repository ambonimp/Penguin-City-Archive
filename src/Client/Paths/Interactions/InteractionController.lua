local InteractionController = {}

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)
local RadialMenu = require(Paths.Client.UI.Elements.RadialMenu)
local Button = require(Paths.Client.UI.Elements.Button)
local InputConstants = require(Paths.Client.Input.InputConstants)

local MAX_PROMPTS_VISIBLE = 5
local GAMEPAD_KEY_CODE = Enum.KeyCode.ButtonX
local KEYBOARD_KEY_CODE = Enum.KeyCode.E
local MAX_ACTIVATION_DISTANCE = 20

local MENU_FONT_SIZE = 35
local MENU_FONT = Enum.Font.Highway

local IS_DESKTOP = DeviceUtil.isDesktop()
local IS_MOBILE = DeviceUtil.isMobile()

type ProximityPromptDict = { [ProximityPrompt]: true? }
type InteractionHandler = (instance: PVInstance, proximityPrompt: ProximityPrompt) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Interactions"
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local interactions: { [string]: { Handler: InteractionHandler, Label: string? } } = {}
local activePrompts: { [ProximityPrompt]: BillboardGui } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
InteractionController.InternalPromptTriggered = Signal.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getAttachedInteractions(instance: PVInstance): { string }
    local attachedInteractions = {}

    for _, tag in pairs(CollectionService:GetTags(instance)) do
        if interactions[tag] then
            table.insert(attachedInteractions, tag)
        end
    end

    return attachedInteractions
end

local function createPrompt(instance: PVInstance)
    if not instance:FindFirstChildOfClass("ProximityPrompt") then
        local proximityPrompt = Instance.new("ProximityPrompt")
        proximityPrompt.Style = Enum.ProximityPromptStyle.Custom
        proximityPrompt.KeyboardKeyCode = KEYBOARD_KEY_CODE
        proximityPrompt.GamepadKeyCode = GAMEPAD_KEY_CODE
        proximityPrompt.MaxActivationDistance = MAX_ACTIVATION_DISTANCE
        proximityPrompt.Parent = instance
        proximityPrompt.RequiresLineOfSight = false
        proximityPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
    end
end

local function invokeHandler(interaction: string, proximityPrompt: ProximityPrompt)
    task.spawn(interactions[interaction].Handler, proximityPrompt.Parent, proximityPrompt)
end

local function onPromptTriggered(proximityPrompt: ProximityPrompt)
    InteractionController.InternalPromptTriggered:Fire(proximityPrompt)

    local instance = proximityPrompt.Parent
    local attachedInteractions = getAttachedInteractions(instance)

    if #attachedInteractions == 1 then
        invokeHandler(attachedInteractions[1], proximityPrompt)
    else
        local radialMenu = RadialMenu.new()
        local maid = radialMenu:GetMaid()

        local menuBillboard: BillboardGui = Instance.new("BillboardGui")
        menuBillboard.Name = "Menu"
        menuBillboard.Size = UDim2.fromOffset(300, 300)
        menuBillboard.AlwaysOnTop = true
        menuBillboard.Adornee = instance
        menuBillboard.Active = true
        menuBillboard.Parent = screenGui
        menuBillboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local container: ImageButton = Instance.new("ImageButton")
        container.AutoButtonColor = false
        container.BackgroundTransparency = 1
        container.Image = ""
        container.Size = UDim2.fromScale(1, 1)
        container.Parent = menuBillboard

        local closed = false
        local function close()
            -- RETURN: Menu is already closed
            if closed then
                return
            end

            closed = true
            proximityPrompt.Enabled = true

            radialMenu:Close():await()
            radialMenu:Destroy()
            menuBillboard:Destroy()
        end

        local longestInteraction = ""
        for _, interaction in pairs(attachedInteractions) do
            if #interaction > #longestInteraction then
                longestInteraction = interaction .. (if IS_DESKTOP then 4 else 0)
            end
        end

        local textSize = TextService:GetTextSize(longestInteraction, MENU_FONT_SIZE, MENU_FONT, camera.ViewportSize)
        local textDim = UDim2.fromOffset(textSize.X, textSize.Y)
        local buttonDim = textDim + UDim2.fromOffset(50, 0)

        for i, interaction in pairs(attachedInteractions) do
            local imageButton: ImageButton = Instance.new("ImageButton")
            imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
            imageButton.Position = UDim2.fromScale(0.5, 0.5)
            imageButton.BackgroundColor3 = Color3.fromRGB(98, 195, 255)
            imageButton.BackgroundTransparency = 0.2
            imageButton.Size = buttonDim

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.new(1, 1, 1)
            stroke.Thickness = 4
            stroke.Parent = imageButton

            local roundedCorners = Instance.new("UICorner")
            roundedCorners.CornerRadius = UDim.new(0.5, 0)
            roundedCorners.Parent = imageButton

            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            textLabel.Position = UDim2.fromScale(0.5, 0.5)
            textLabel.Size = textDim
            textLabel.Font = MENU_FONT
            textLabel.TextSize = MENU_FONT_SIZE
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.Text = if IS_DESKTOP then ("%s (%d)"):format(interaction, i) else interaction
            textLabel.TextWrapped = false
            textLabel.TextTruncate = Enum.TextTruncate.None
            textLabel.Parent = imageButton

            radialMenu:AddButton(Button.new(imageButton)).Pressed:Connect(function()
                close()
                invokeHandler(interaction, proximityPrompt)
            end)
        end

        container.MouseButton1Down:Connect(close)

        maid:GiveTask(InteractionController.InternalPromptTriggered:Connect(function()
            close()
        end))

        if DeviceUtil.isDesktop() then
            radialMenu:GetMaid():GiveTask(UserInputService.InputBegan:Connect(function(input)
                local index = InputConstants.KeyCodeNumbers[input.KeyCode]
                if index then
                    close()
                    invokeHandler(attachedInteractions[index], proximityPrompt)
                end
            end))
        end

        proximityPrompt.Enabled = false
        radialMenu:Mount(container)
        radialMenu:Open()
    end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function InteractionController.registerInteraction(interaction: string, handler: InteractionHandler, label: string?)
    -- ERROR: Interaction has already been registered
    if interactions[interaction] then
        error(("Interaction %s has already been registered"):format(interaction))
    end

    interactions[interaction] = { Handler = handler, Label = label }

    -- Adding
    for _, instance in pairs(CollectionService:GetTagged(interaction)) do
        createPrompt(instance)
    end
    CollectionService:GetInstanceAddedSignal(interaction):Connect(createPrompt)

    -- Removing
    CollectionService:GetInstanceRemovedSignal(interaction):Connect(function(instance)
        if #getAttachedInteractions(instance) == 0 then
            instance:FindFirstChildOfClass("ProximityPrompt"):Destroy()
        end
    end)
end

function InteractionController.attachInteraction(instance: PVInstance, interaction: string)
    -- ERROR: Interaction hasn't been registered
    if not interactions[interaction] then
        error(("Attempt to add an unregistered interaction(%s) to an instance"):format(interaction))
    end

    CollectionService:AddTag(instance, interaction)
end

function InteractionController.detachInteraction(instance, interaction: string)
    CollectionService:RemoveTag(instance, interaction)
end

function InteractionController.detachAllInteractions(instance: PVInstance)
    for _, interaction in pairs(getAttachedInteractions(instance)) do
        InteractionController.detachInteraction(instance, interaction)
    end
end

function InteractionController.getAllPromptsOfType(interaction: string): { ProximityPrompt }
    -- ERROR: Interaction hasn't been registered
    if not interactions[interaction] then
        error(("Attempt to get proximity prompts of an unregistered interaction"):format(interaction))
    end

    local proximityPrompts = {}

    for _, instance in pairs(CollectionService:GetTagged(interaction)) do
        table.insert(proximityPrompts, instance:FindFirstChildOfClass("ProximityPrompt"))
    end

    return proximityPrompts
end

function InteractionController.Init()
    -- Require handlers
    for _, moduleScript in ipairs(Paths.Client.Interactions.Handlers:GetDescendants()) do
        require(moduleScript)
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
local shownProximityPrompts: ProximityPromptDict = {}
local prevShownProximityPrompt: ProximityPromptDict = {}
local focusedProximityPrompt: ProximityPrompt?

ProximityPromptService.MaxPromptsVisible = MAX_PROMPTS_VISIBLE
ProximityPromptService.PromptShown:Connect(function(proximityPrompt)
    local instance: PVInstance = proximityPrompt.Parent
    local attachedInteractions = getAttachedInteractions(instance)

    local promptBillboard: BillboardGui = Paths.Templates.ProximityPrompt:Clone()
    promptBillboard.Adornee = instance
    promptBillboard.Parent = screenGui
    activePrompts[proximityPrompt] = promptBillboard

    local promptButton: ImageButton = promptBillboard.Button
    local label: TextLabel = promptButton.Label
    label.Text = (if #attachedInteractions == 1 then interactions[attachedInteractions[1]].Label else nil) or ""
    label.Visible = false

    promptButton.MouseButton1Down:Connect(function()
        onPromptTriggered(proximityPrompt)
    end)

    promptButton.MouseEnter:Connect(function()
        label.Visible = true
    end)

    promptButton.MouseLeave:Connect(function()
        label.Visible = false
    end)

    shownProximityPrompts[proximityPrompt] = true
end)

ProximityPromptService.PromptHidden:Connect(function(proximityPrompt)
    activePrompts[proximityPrompt]:Destroy()
    activePrompts[proximityPrompt] = nil
    shownProximityPrompts[proximityPrompt] = nil
end)

ProximityPromptService.PromptTriggered:Connect(function(proximityPrompt)
    if proximityPrompt == focusedProximityPrompt then
        onPromptTriggered(proximityPrompt)
    end
end)

-- Focus
if not IS_MOBILE then
    RunService.RenderStepped:Connect(function()
        for proximityPrompt in pairs(prevShownProximityPrompt) do
            if not shownProximityPrompts[proximityPrompt] then
                prevShownProximityPrompt[proximityPrompt] = nil
            end
        end

        local _focusedProximityPrompt: ProximityPrompt = nil
        local largestAlignment: number = -1
        local cameraCFrame: CFrame = camera.CFrame
        local cameraLook: Vector3 = cameraCFrame.LookVector

        for proximityPrompt in pairs(shownProximityPrompts) do
            local instance = proximityPrompt.Parent
            local position: Vector3 = (if instance:IsA("Model") then instance.WorldPivot else instance.CFrame).Position
            local offsetLook: Vector3 = CFrame.new(cameraCFrame.Position, position).LookVector
            local dot = cameraLook:Dot(offsetLook)

            if dot > largestAlignment then
                _focusedProximityPrompt = proximityPrompt
                largestAlignment = dot
            end
        end

        focusedProximityPrompt = _focusedProximityPrompt
        for proximityPrompt in pairs(shownProximityPrompts) do
            local input: Frame = activePrompts[proximityPrompt].Button.Input

            if proximityPrompt == focusedProximityPrompt then
                input.ClickIcon.Visible = false
                input.KeyCodeText.Visible = true
            else
                input.ClickIcon.Visible = true
                input.KeyCodeText.Visible = false
            end

            prevShownProximityPrompt[proximityPrompt] = true
        end
    end)
end

return InteractionController
