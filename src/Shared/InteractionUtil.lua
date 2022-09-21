local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local InteractionUtil = {}

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

if RunService:IsClient() then
    -- Disbales proximity prompt
    -- Keeps track of requests so that there is no conflicts between scripts when re-enabling
    local disableRequests = {}
    function InteractionUtil.toggleVisible(request, toggle)
        if toggle then
            table.remove(disableRequests, table.find(disableRequests, request))
            if #disableRequests == 0 then
                ProximityPromptService.Enabled = true
            end
        else
            if not table.find(disableRequests, request) then
                table.insert(disableRequests, request)
                ProximityPromptService.Enabled = false
            end
        end
    end
end

return InteractionUtil
