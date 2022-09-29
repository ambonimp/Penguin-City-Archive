local InteractionUtil = {}

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Toggle = require(ReplicatedStorage.Shared.Toggle)

local arePromptsHidden = Toggle.new(false, function(value)
    ProximityPromptService.Enabled = not value
end)

function InteractionUtil.createInteraction(interactable, props)
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.RequiresLineOfSight = false

    for prop, value in props do
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

return InteractionUtil
