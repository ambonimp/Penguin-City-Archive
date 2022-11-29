local MinigameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

local constants = {}
for minigame in pairs(MinigameConstants.Minigames) do
    if minigame ~= "Pizza" then
        constants[minigame] = require(ReplicatedStorage.Shared.Minigames[minigame][minigame .. "Constants"])
    end
end

function MinigameUtil.getsessionConfig(minigameName: string): MinigameConstants.SessionConfig
    return constants[minigameName].SessionConfig
end

function MinigameUtil.formatScore(minigameName: string, score: number): number | string
    local formatter = MinigameUtil.getsessionConfig(minigameName).ScoreFormatter
    return if formatter then formatter(score) else score
end

function MinigameUtil.getSessionConfigFromQueueStation(queueStation: Model): table?
    if queueStation then
        return {
            MinParticipants = queueStation:GetAttribute("MinParticipant"),
            MaxParticipants = queueStation:GetAttribute("MaxParticipant"),
        }
    end
end

return MinigameUtil
