--[[
    - Verifies that players playing PizzaMinigame aren't cheating
    - Rewards players after finishing the minigame
    ]]
local PizzaMinigameService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Paths.Shared.Minigames.Pizza.PizzaMinigameUtil)
local Output = require(Paths.Shared.Output)

type RecipeRecord = {
    WasCorrect: boolean,
    Tick: number,
}

type PlayerData = {
    RecipeTypeOrder: { string },
    RecipeRecords: { RecipeRecord },
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
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame", player)

    -- Init PlayerData
    local playerData: PlayerData = {
        RecipeTypeOrder = { PizzaMinigameConstants.FirstRecipe },
        RecipeRecords = {},
    }
    playerDatas[player] = playerData

    -- Generate RecipeTypeOrder
    for pizzaNumber = 2, PizzaMinigameConstants.MaxPizzas do
        local recipeLabel, _recipe = PizzaMinigameUtil.rollRecipeType(pizzaNumber)
        table.insert(playerData.RecipeTypeOrder, recipeLabel)
    end

    -- Inform client of their recipe order
    Remotes.fireClient(player, "PizzaMinigameRecipeTypeOrder", playerData.RecipeTypeOrder)
end

function PizzaMinigameService.stopMinigame(player: Player)
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame", player)

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
    local recipeTypeOrder = playerData.RecipeTypeOrder
    for pizzaNumber = 1, totalPizzas do
        local recipe = recipeTypeOrder[pizzaNumber]
        local recipeMinTime = MIN_RECIPE_TIMES[recipe]
        minimumTime += recipeMinTime
    end
    local firstPizzaTime = MIN_RECIPE_TIMES[PizzaMinigameConstants.FirstRecipe]
    local actualTime = totalPizzas >= 2 and (playerData.RecipeRecords[2].Tick - playerData.RecipeRecords[1].Tick) + firstPizzaTime or 0
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

function PizzaMinigameService.developerToLive(minigamesDirectory: Folder)
    -- Hide Guides & Hitboxes
    local minigameFolder = minigamesDirectory:WaitForChild("Pizza")
    for _, directory: Instance in pairs({ minigameFolder.Guides, minigameFolder.Hitboxes }) do
        for _, descendant: BasePart in pairs(directory:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Transparency = 1
            end
        end
    end
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
