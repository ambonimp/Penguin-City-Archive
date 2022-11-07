local MinigameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

function MinigameUtil.getSessionConfigs(minigameName: string): MinigameConstants.SessionConfig
    return require(ReplicatedStorage.Shared.Minigames[minigameName][minigameName .. "Constants"]).SessionConfig
end

return MinigameUtil
