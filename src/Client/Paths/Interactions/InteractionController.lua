local InteractionController = {}

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)

local MAX_PROMPTS_VISIBLE = 5
local GAMEPAD_KEY_CODE = Enum.KeyCode.ButtonX
local KEYBOARD_KEY_CODE = Enum.KeyCode.E
local MAX_ACTIVATION_DISTANCE = 20

type ProximityPromptDict = { [ProximityPrompt]: true? }
type InteractionHandler = (instance: PVInstance, prompt: ProximityPrompt) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProximityPrompts"
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local interactions: { [string]: { Handler: InteractionHandler, Label: string? } } = {}
local activePrompts: { [ProximityPrompt]: BillboardGui } = {}

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

local function onPromptTriggered(proximityPrompt: ProximityPrompt)
    local instance = proximityPrompt.Parent
    local attachedInteractions = getAttachedInteractions(instance)

    if #attachedInteractions == 1 then
        interactions[attachedInteractions[1]].Handler(instance, proximityPrompt)
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

    local prompt: BillboardGui = Paths.Templates.ProximityPrompt:Clone()
    prompt.Adornee = instance
    prompt.Parent = screenGui
    activePrompts[proximityPrompt] = prompt

    local promptButton: ImageButton = prompt.Button

    local label: TextLabel = promptButton.Label
    label.Text = (if #attachedInteractions == 1 then interactions[attachedInteractions[1]].Label else nil) or ""

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
if not DeviceUtil.isMobile() then
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
