local RewardsStampAwarders = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local RewardsService = require(Paths.Server.RewardsService)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local PizzaFiascoConstants = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoConstants)
local PizzaFiascoSession = require(Paths.Server.Minigames.PizzaFiasco.PizzaFiascoSession)

local pizzaPlayStamp = StampUtil.getStampFromId("minigame_pizza_play")
local pizzaLoseStamp = StampUtil.getStampFromId("minigame_pizza_lose")
local pizzaCorrect5Stamp = StampUtil.getStampFromId("minigame_pizza_correct5")
local pizzaExraLifeStamp = StampUtil.getStampFromId("minigame_pizza_extralife")
local pizzaCorrect25Stamp = StampUtil.getStampFromId("minigame_pizza_correct25")

-- minigame_pizza_play, minigame_pizza_lose
MinigameSession.MinigameFinished:Connect(
    function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
        -- RETURN: Not pizza fiasco
        if not (minigameSession:GetMinigameName() == MinigameConstants.Minigames.PizzaFiasco) then
            return
        end

        for _position, scoreData in pairs(sortedScores) do
            print(scoreData.Player, scoreData.Score)

            -- Played
            StampService.addStamp(scoreData.Player, pizzaPlayStamp.Id)

            -- Lost
            local didLose = scoreData.Score < (PizzaFiascoConstants.MaxPizzas - PizzaFiascoConstants.MaxMistakes) -- doesn't account for extra life.. sorry
            if didLose then
                StampService.addStamp(scoreData.Player, pizzaLoseStamp.Id)
            end
        end
    end
)

-- pizzaCorrect5Stamp, pizzaCorrect25Stamp, pizzaExraLifeStamp
PizzaFiascoSession.RecipeRecordUpdated:Connect(function(player: Player, recipeRecords: { PizzaFiascoSession.RecipeRecord })
    -- Get how many correct in a row
    local totalCorrectPizzasInARow = 0
    for i = #recipeRecords, 1, -1 do
        local recipeRecord = recipeRecords[i]
        if recipeRecord.WasCorrect or recipeRecord.DoSubtractMistake then
            totalCorrectPizzasInARow += 1
        else
            break
        end
    end

    -- Was the latest recipe record a subtraction / extra life?
    local didUseExtraLife = recipeRecords[#recipeRecords].DoSubtractMistake

    -- Award Stamps
    if totalCorrectPizzasInARow >= 5 then
        StampService.addStamp(player, pizzaCorrect5Stamp.Id)
    end

    if totalCorrectPizzasInARow >= 25 then
        StampService.addStamp(player, pizzaCorrect25Stamp.Id)
    end

    if didUseExtraLife then
        StampService.addStamp(player, pizzaExraLifeStamp.Id)
    end
end)

return RewardsStampAwarders
