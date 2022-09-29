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
local TableUtil = require(Paths.Shared.Utils.TableUtil)

type RecipeRecord = {
    WasCorrect: boolean,
    Tick: number,
}

type PlayerData = {
    RecipeTypeOrder: { string },
    RecipeRecords: { RecipeRecord },
    PlayRequestTick: number,
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
local CLEANUP_PLAYER_DATA_AFTER = 5

local startedPlayers: { Player } = {} -- Players currently in this minigame
local playerDatas: { [Player]: PlayerData } = {} -- Data of current gameplay sessions

-------------------------------------------------------------------------------
-- Gameplay
-------------------------------------------------------------------------------

function PizzaMinigameService.isPlaying(player: Player)
    return playerDatas[player] and true or false
end

function PizzaMinigameService.playRequest(player: Player)
    Output.doDebug(MinigameConstants.DoDebug, "playRequest", player)

    -- RETURN: Already playing
    if PizzaMinigameService.isPlaying(player) then
        Output.doDebug(MinigameConstants.DoDebug, player, "already playing")
        return
    end

    -- Init PlayerData
    local playerData: PlayerData = {
        RecipeTypeOrder = { PizzaMinigameConstants.FirstRecipe },
        RecipeRecords = {},
        PlayRequestTick = tick(),
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

function PizzaMinigameService.finishRequest(player: Player)
    Output.doDebug(MinigameConstants.DoDebug, "finishRequest", player)

    -- RETURN: Wasn't playing
    if not PizzaMinigameService.isPlaying(player) then
        Output.doDebug(MinigameConstants.DoDebug, player, "wasn't playing")
        return
    end

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
    local actualTime = totalPizzas > 0 and (playerData.RecipeRecords[totalPizzas].Tick - playerData.PlayRequestTick) + firstPizzaTime or 0
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
    else
        warn(("%s finished pizza too quickly (Min Time: %.2f, Actual Time: %.2f)"):format(player.Name, minimumTime, actualTime))
    end

    -- Cleanup
    playerDatas[player] = nil
end

function PizzaMinigameService.completedPizza(player: Player, dirtyWasCorrect: any)
    Output.doDebug(MinigameConstants.DoDebug, "completedPizza", player)

    -- RETURN: Not playing
    if not PizzaMinigameService.isPlaying(player) then
        Output.doDebug(MinigameConstants.DoDebug, player, "wasn't playing")
        return
    end

    -- Verify + Clean parameters
    local wasCorrect = TypeUtil.toBoolean(dirtyWasCorrect) and true or false

    -- Store Record
    local playerData = playerDatas[player]
    local recipeRecord: RecipeRecord = {
        WasCorrect = wasCorrect,
        Tick = tick(),
    }
    table.insert(playerData.RecipeRecords, recipeRecord)
end

-------------------------------------------------------------------------------
-- Internals
-------------------------------------------------------------------------------

function PizzaMinigameService.hasPlayerStarted(player: Player)
    return table.find(startedPlayers, player) and true or false
end

function PizzaMinigameService.startMinigame(player: Player)
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame", player)
    table.insert(startedPlayers, player)
end

function PizzaMinigameService.stopMinigame(player: Player)
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame", player)
    TableUtil.remove(startedPlayers, player)

    -- After a delay, clear the cache. It's possible this stopMinigame call was the first the client knew about the minigame stopping.
    -- They may still need to request the minigame to finish on their end!
    task.delay(CLEANUP_PLAYER_DATA_AFTER, function()
        if not PizzaMinigameService.hasPlayerStarted(player) then
            playerDatas[player] = nil
        end
    end)
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
        PizzaMinigamePlay = PizzaMinigameService.playRequest,
        PizzaMinigameFinsh = PizzaMinigameService.finishRequest,
        PizzaMinigameCompletedPizza = PizzaMinigameService.completedPizza,
    })
end

return PizzaMinigameService
