local IceCreamExtravaganzaStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local iceCreamExtravaganzaWinsTieredStamp = StampUtil.getStampFromId("minigame_icecream_wins")
local playIceCreamExtravaganzaStamp = StampUtil.getStampFromId("minigame_icecream_play") --todo
local collectScoops5Stamp = StampUtil.getStampFromId("minigame_icecream_collect5") --todo
local collectScoops10Stamp = StampUtil.getStampFromId("minigame_icecream_collect10") --todo

-- minigame_sledrace_wins
MinigameSession.MinigameFinished:Connect(
    function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
        -- RETURN: Not ice cream extravaganza
        if not (minigameSession:GetMinigameName() == MinigameConstants.Minigames.IceCreamExtravaganza) then
            return
        end

        local winnerPlayer = sortedScores[1] and sortedScores[1].Player
        if winnerPlayer then
            StampService.incrementStamp(winnerPlayer, iceCreamExtravaganzaWinsTieredStamp.Id, 1)
        end
    end
)

return IceCreamExtravaganzaStampAwarders
