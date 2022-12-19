local IceCreamExtravaganzaStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local IceCreamExtravaganzaSession = require(Paths.Server.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaSession)

local iceCreamExtravaganzaWinsTieredStamp = StampUtil.getStampFromId("minigame_icecream_wins")
local playIceCreamExtravaganzaStamp = StampUtil.getStampFromId("minigame_icecream_play")
local collectScoops5Stamp = StampUtil.getStampFromId("minigame_icecream_collect5")
local collectScoops10Stamp = StampUtil.getStampFromId("minigame_icecream_collect10")

-- minigame_icecream_wins, minigame_icecream_play
MinigameSession.MinigameFinished:Connect(
    function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
        -- RETURN: Not ice cream extravaganza
        if not (minigameSession:GetMinigameName() == MinigameConstants.Minigames.IceCreamExtravaganza) then
            return
        end

        -- Play
        for _, score in pairs(sortedScores) do
            StampService.addStamp(score.Player, playIceCreamExtravaganzaStamp.Id)
        end

        -- Wins
        local winnerPlayer = sortedScores[1] and sortedScores[1].Player
        if winnerPlayer then
            StampService.incrementStamp(winnerPlayer, iceCreamExtravaganzaWinsTieredStamp.Id, 1)
        end
    end
)

IceCreamExtravaganzaSession.CollectableCollected:Connect(
    function(session: IceCreamExtravaganzaSession.IceCreamExtravaganzaSession, player: Player, _collectableType: string, _scoreIncrement: number?)
        local currentScore = session:GetParticipantScore(player) or 0

        -- 5 Scoops
        if currentScore >= 5 then
            StampService.addStamp(player, collectScoops5Stamp.Id)
        end

        -- 10 Scoops
        if currentScore >= 10 then
            StampService.addStamp(player, collectScoops10Stamp.Id)
        end
    end
)

return IceCreamExtravaganzaStampAwarders
