local PizzaFiascoSession = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local PizzaFiascoConstants = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoConstants)
local PizzaFiascoUtil = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoUtil)
local Output = require(Paths.Shared.Output)
local CurrencyService = require(Paths.Server.CurrencyService)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)

type RecipeRecord = {
    WasCorrect: boolean,
    Tick: number,
    DoSubtractMistake: boolean,
}

type participantData = {
    RecipeTypeOrder: { string },
    RecipeRecords: { RecipeRecord },
    PlayRequestTick: number,
}

local MINGIAME_NAME = "PizzaFiasco"
local MIN_RECIPE_TIMES = {
    A = 0.5,
    B = 1,
    C = 1.5,
    D = 2,
    E = 2,
    F = 2,
    G = 2,
    -- Failsafe for missing entries
    __index = function(_, index)
        warn(("No recipe time defined for recipe %q"):format(index))
        return 0
    end,
}
local MAXIMUM_RECIPE_TYPE_REPEATS_REROLLS = 5

function PizzaFiascoSession.new(id: string, participants: { Player }, isMultiplayer: boolean)
    local minigameSession = MinigameSession.new(MINGIAME_NAME, id, participants, isMultiplayer)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local coreJanitor = Maid.new()
    local maid = minigameSession:GetMaid()
    maid:GiveTask(coreJanitor)

    local participantData: {
        RecipeTypeOrder: { string },
        RecipeRecords: { RecipeRecord },
        PlayRequestTick: number,
    }?

    minigameSession:SetDefaultScore(0)

    -------------------------------------------------------------------------------
    -- State handlers
    -------------------------------------------------------------------------------
    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Core, function()
        participantData = {
            RecipeTypeOrder = { PizzaFiascoConstants.FirstRecipe },
            RecipeRecords = {},
            PlayRequestTick = tick(),
        }

        -- Generate RecipeTypeOrder (ensure we don't have long repeats)
        for pizzaNumber = 2, PizzaFiascoConstants.MaxPizzas do
            local recipeLabel: string
            local totalRerolls = 0
            while totalRerolls < MAXIMUM_RECIPE_TYPE_REPEATS_REROLLS do
                local internalRecipeLabel, _recipe = PizzaFiascoUtil.rollRecipeType(pizzaNumber)
                recipeLabel = internalRecipeLabel

                local repeatsBefore = 0
                for i = (pizzaNumber - 1), 1, -1 do
                    if participantData.RecipeTypeOrder[i] == recipeLabel then
                        repeatsBefore += 1
                    else
                        break
                    end
                end

                if repeatsBefore < PizzaFiascoConstants.MaxRecipeRepeats then
                    break
                else
                    totalRerolls += 1
                end
            end
            table.insert(participantData.RecipeTypeOrder, recipeLabel)
        end

        -- Inform client of their recipe order
        minigameSession:RelayToParticipants("PizzaFiascoRecipeTypeOrder", participantData.RecipeTypeOrder)

        coreJanitor:GiveTask(
            Remotes.bindEventTemp("PizzaFiascoPizzaCompleted", function(player: Player, dirtyWasCorrect: any, dirtyDoSubtractMistake: any)
                -- RETURN: Wrong session
                if not minigameSession:IsPlayerParticipant(player) then
                    return
                end

                Output.doDebug(MinigameConstants.DoDebug, "completedPizza", player)

                -- Verify + Clean parameters
                local wasCorrect = TypeUtil.toBoolean(dirtyWasCorrect, false)
                local doSubtractMistake = TypeUtil.toBoolean(dirtyDoSubtractMistake, false)

                -- Store Record
                local recipeRecord: RecipeRecord = {
                    WasCorrect = wasCorrect,
                    Tick = tick(),
                    DoSubtractMistake = doSubtractMistake,
                }

                table.insert(participantData.RecipeRecords, recipeRecord)
            end)
        )

        coreJanitor:GiveTask(Remotes.bindEventTemp("PizzaMinigameRoundFinished", function(player: Player)
            -- RETURN: Wrong session
            if not minigameSession:IsPlayerParticipant(player) then
                return
            end

            -- Calculate total correct/wrong pizzas
            local playerRecipeRecords = participantData.RecipeRecords
            local totalPizzas = #playerRecipeRecords
            local totalCorrectPizzas = 0
            local totalMistakes = 0
            local doSubtractMistakeCount = 0
            for _, recipeRecord in pairs(playerRecipeRecords) do
                if recipeRecord.DoSubtractMistake then
                    doSubtractMistakeCount += 1
                    totalCorrectPizzas += 1
                    totalMistakes -= 1
                else
                    if recipeRecord.WasCorrect then
                        totalCorrectPizzas += 1
                    else
                        totalMistakes += 1
                    end
                end
            end

            -- Verify completion time
            local minimumTime = 0
            local recipeTypeOrder = participantData.RecipeTypeOrder
            for pizzaNumber = 1, totalPizzas do
                local recipe = recipeTypeOrder[pizzaNumber]
                local recipeMinTime = MIN_RECIPE_TIMES[recipe]
                minimumTime += recipeMinTime
            end
            local firstPizzaTime = MIN_RECIPE_TIMES[PizzaFiascoConstants.FirstRecipe]
            local actualTime = totalPizzas > 0
                    and (participantData.RecipeRecords[totalPizzas].Tick - participantData.PlayRequestTick) + firstPizzaTime
                or 0
            local finishedTooQuickly = actualTime < minimumTime

            -- Give reward
            local doGiveReward = not finishedTooQuickly
                and (totalMistakes <= PizzaFiascoConstants.MaxMistakes)
                and (doSubtractMistakeCount <= 1)
            if doGiveReward then
                CurrencyService.addCoins(player, totalCorrectPizzas, true)
            else
                warn(
                    ("%s had an issue. FinishedTooQuickly: %s (Min Time: %.2f, Actual Time: %.2f). Total Mistakes: %d. DoSubtractMistakeCount: %d"):format(
                        player.Name,
                        tostring(finishedTooQuickly),
                        minimumTime,
                        actualTime,
                        totalMistakes,
                        doSubtractMistakeCount
                    )
                )
            end

            minigameSession:ChangeState(MinigameConstants.States.AwardShow)
        end))
    end, function()
        participantData = nil
        coreJanitor:Cleanup()
    end)

    minigameSession:Start()
    return minigameSession
end

-------------------------------------------------------------------------------
-- Initialize map template
-------------------------------------------------------------------------------
do
    -- Hide Guides & Hitboxes
    local mapTemplate = ServerStorage.Minigames[MINGIAME_NAME].Map
    for _, directory: Instance in pairs({ mapTemplate.Guides, mapTemplate.Hitboxes }) do
        for _, descendant: BasePart in pairs(directory:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Transparency = 1
            end
        end
    end

    -- Hide Ingredient Labels
    for _, surfaceGui: SurfaceGui in pairs(mapTemplate.Labels:GetDescendants()) do
        if surfaceGui:IsA("SurfaceGui") then
            surfaceGui.Enabled = false
        end
    end

    -- Hide Heart
    ReplicatedStorage.Assets.Minigames.PizzaFiasco.Pizza.Heart.Decal.Transparency = 1
end

-- Communication
do
    Remotes.declareEvent("PizzaFiascoRecipeTypeOrder")
    Remotes.declareEvent("PizzaFiascoPizzaCompleted")
    Remotes.declareEvent("PizzaMinigameRoundFinished")
end

return PizzaFiascoSession
