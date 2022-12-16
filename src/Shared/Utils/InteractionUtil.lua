local InteractionUtil = {}

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Toggle = require(ReplicatedStorage.Shared.Toggle)
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

local arePromptsHidden = Toggle.new(false, function(value)
    ProximityPromptService.Enabled = not value
end)

-------------------------------------------------------------------------------
-- Generic API
-------------------------------------------------------------------------------

function InteractionUtil.createInteraction(interactable: Instance, props: { [string]: any }?)
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.RequiresLineOfSight = false

    for prop, value in pairs(props) do
        proximityPrompt[prop] = value
    end

    proximityPrompt.Parent = interactable
    return proximityPrompt
end

function InteractionUtil.hideInteractions(requester: string)
    arePromptsHidden:Set(true, requester)
end

function InteractionUtil.showInteractions(requester: string)
    arePromptsHidden:Set(false, requester)
end

-------------------------------------------------------------------------------
-- Minigames
-------------------------------------------------------------------------------

function InteractionUtil.getMinigamePromptDataFromInteractionInstance(instance: Instance)
    local queueStation = instance.Parent
    local isMultiplayer = queueStation:GetAttribute("Multiplayer")
    local minigame: string = queueStation:GetAttribute("Minigame")

    -- ERROR: Missing attributes
    do
        if isMultiplayer == nil then
            error(("MinigamePrompt QueueStation %s missing Attribute `Multiplayer`"):format(queueStation:GetFullName()))
        end
        if minigame == nil then
            error(("MinigamePrompt QueueStation %s missing Attribute `Minigame`"):format(queueStation:GetFullName()))
        end
    end

    -- ERROR: Bad minigame
    if not MinigameConstants.Minigames[minigame] then
        error(("MinigamePrompt QueueStation %s, bad minigame %q"):format(queueStation:GetFullName(), minigame))
    end

    return {
        QueueStation = queueStation,
        IsMultiplayer = isMultiplayer and true or false,
        Minigame = minigame,
    }
end

return InteractionUtil
