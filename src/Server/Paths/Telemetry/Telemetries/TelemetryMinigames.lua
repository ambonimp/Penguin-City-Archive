local TelemetryMinigames = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

-- Summary
MinigameSession.MinigameFinished:Connect(function(session: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
    for rank, scoreInfo in pairs(sortedScores) do
        TelemetryService.postPlayerEvent(scoreInfo.Player, "miniGameSummary", {
            -- Generic Data
            miniGameSessionTime = math.round(session:GetSessionTime()),
            miniGameName = StringUtil.toCamelCase(session:GetMinigameName()),
            numberOfPlayers = #sortedScores,

            -- Specific Data
            rank = rank,
            coinsEarned = scoreInfo.CoinsEarned,
        })
    end
end)

-- Initiated
MinigameSession.ParticipantedAdded:Connect(function(session: MinigameSession.MinigameSession, player: Player)
    TelemetryService.postPlayerEvent(player, "miniGameInitiated", {
        miniGameName = StringUtil.toCamelCase(session:GetMinigameName()),
    })
end)

return TelemetryMinigames
