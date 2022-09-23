--[[
    - Verifies that players playing PizzaMinigame aren't cheating
    - Rewards players after finishing the minigame
    ]]
local PizzaMinigameService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Modules = Paths.Modules
local Remotes = require(Modules.Remotes)
local TypeUtil = require(Modules.Utils.TypeUtil)
local PizzaMinigameConstants = require(Modules.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Modules.Minigames.Pizza.PizzaMinigameUtil)

type RecipeRecord = {
    WasCorrect: boolean,
    Tick: number,
}

type PlayerData = {
    RecipeOrder: { string },
    RecipeRecords: { RecipeRecord },
    StartTick: number,
}

local MIN_RECIPE_TIMES = {
    A = 1,
    B = 2,
    C = 2.5,
    D = 3,

    -- Failsafe for missing entries
    __index = function(_, index)
        warn(("No recipe time defined for recipe %q"):format(index))
        return 0
    end,
}

local playerDatas: { [Player]: PlayerData } = {}

function PizzaMinigameService.startMinigame(player: Player)
    -- Init PlayerData
    local playerData: PlayerData = {
        RecipeOrder = {},
        RecipeRecords = {},
        StartTick = tick(),
    }
    playerDatas[player] = playerData

    -- Generate Recipe Order
    for pizzaNumber = 1, PizzaMinigameConstants.MaxPizzas do
        table.insert(playerData.RecipeOrder, PizzaMinigameUtil.rollRecipe(pizzaNumber))
    end

    -- Inform client of their recipe order
    Remotes.fireClient(player, "PizzaMinigameRecipeOrder", playerData.RecipeOrder)
end

function PizzaMinigameService.stopMinigame(player: Player)
    -- Get PlayerData
    local playerData = playerDatas[player]

    -- Calculate total correct pizzas
    local playerRecipeRecords = playerData.RecipeRecords
    local totalPizzas = #playerRecipeRecords
    local totalCorrectPizzas = 0
    for _, recipeRecord in pairs(playerRecipeRecords) do
        if recipeRecord.WasCorrect then
            totalCorrectPizzas += 1
        end
    end

    -- Verify completion time
    local minimumTime = 0
    local recipeOrder = playerData.RecipeOrder
    for pizzaNumber = 1, totalPizzas do
        local recipe = recipeOrder[pizzaNumber]
        local recipeMinTime = MIN_RECIPE_TIMES[recipe]
        minimumTime += recipeMinTime
    end
    local actualTime = totalPizzas > 0 and playerData.RecipeRecords[1].Tick - playerData.StartTick or 0
    local finishedTooQuickly = actualTime < minimumTime

    -- Calculate reward
    local totalReward = 0
    for pizzaNumber, recipeRecord in pairs(playerRecipeRecords) do
        if recipeRecord.WasCorrect then
            totalReward += PizzaMinigameUtil.calculatePizzaReward(pizzaNumber)
        end
    end

    -- Give reward
    local doGiveReward = not finishedTooQuickly
    if doGiveReward then
        warn(("TODO: Give %s %d coins for completing %d/%d pizzas!"):format(player.Name, totalReward, totalCorrectPizzas, totalPizzas))
    end

    -- Cleanup
    playerDatas[player] = nil
end

-- Setup Communication
do
    Remotes.bindEvents({
        PizzaMinigameCompletedPizza = function(player: Player, dirtyWasCorrect: any)
            -- Verify + Clean parameters
            local wasCorrect = TypeUtil.toBoolean(dirtyWasCorrect) and true or false

            -- RETURN: Player not playing!
            local playerData = playerDatas[player]
            if not playerData then
                warn(("Recieved PizzaMinigameCompletedPizza event from %s; they are not playing!"):format(player.Name))
                return
            end

            -- Store Record
            local recipeRecord: RecipeRecord = {
                WasCorrect = wasCorrect,
                Tick = tick(),
            }
            table.insert(playerData.RecipeRecords, recipeRecord)
        end,
    })
end

return PizzaMinigameService
