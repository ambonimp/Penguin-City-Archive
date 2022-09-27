local PizzaMinigameRunner = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local CameraController = require(Paths.Client.CameraController)
local InputController = require(Paths.Client.Input.InputController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Paths.Shared.Minigames.Pizza.PizzaMinigameUtil)
local PizzaMinigameOrder = require(Paths.Client.Minigames.Pizza.PizzaMinigameOrder)
local Output = require(Paths.Shared.Output)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local RAYCAST_LENGTH = 100
local CAMERA_SWAY_MAX_ANGLE = 4

function PizzaMinigameRunner.new(minigameFolder: Folder, recipeTypeOrder: { string })
    local runner = {}
    Output.doDebug(MinigameConstants.DoDebug, "new")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local pizzaMaid = Maid.new()
    maid:GiveTask(pizzaMaid)

    local gameplayFolder: Folder
    local order: typeof(PizzaMinigameOrder.new())

    local currentHitbox: BasePart | nil
    local hitboxParts: { BasePart } = {}

    local pizzaLine: BasePart = minigameFolder.Guides.PizzaLine
    local pizzaStartCFrame = CFrame.new(pizzaLine.Position - (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))
    local pizzaEndCFrame = CFrame.new(pizzaLine.Position + (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))

    local totalPizzasMade = 0
    local totalMistakes = 0
    local totalCorrectPizzasInARow = 0
    local totalCoinsEarnt = 0

    local pizzaModel: Model

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local sendPizza: () -> nil -- Hoist this function
    -- Client has just finished a pizza
    local function pizzaUpdate(didComplete: boolean)
        Output.doDebug(MinigameConstants.DoDebug, "pizzaUpdate")

        -- Update Internal counts
        totalPizzasMade += 1
        if didComplete then
            totalCoinsEarnt += PizzaMinigameUtil.calculatePizzaReward(totalPizzasMade)
            totalCorrectPizzasInARow += 1
        else
            totalMistakes += 1
            totalCorrectPizzasInARow = 0
        end

        -- GAME FINISHED
        if totalPizzasMade == PizzaMinigameConstants.MaxPizzas then
            warn("TODO GAME FINISHED")
            return
        end

        --todo inform server

        -- Update Orders
        order:SetCoinsEarnt(totalCoinsEarnt)
        order:SetPizzaCounts(totalPizzasMade, PizzaMinigameConstants.MaxPizzas - totalPizzasMade, totalMistakes)

        -- Move onto next pizza
        sendPizza()
    end

    function sendPizza()
        Output.doDebug(MinigameConstants.DoDebug, "sendPizza")

        -- Cleanup last pizza
        pizzaMaid:Cleanup()

        -- Pizza Model
        local pizzaTime = PizzaMinigameConstants.Conveyor.Speed
            * (PizzaMinigameConstants.Conveyor.IncreaseFactor ^ totalCorrectPizzasInARow)
        do
            -- Place Pizza Model
            pizzaModel = minigameFolder.Assets.Pizza:Clone()
            pizzaModel:PivotTo(pizzaStartCFrame)
            pizzaModel.Parent = gameplayFolder
            pizzaMaid:GiveTask(pizzaModel)

            -- Setup Pizza Model movement
            local pizzaMoveTweenInfo = TweenInfo.new(pizzaTime, Enum.EasingStyle.Linear)
            pizzaMaid:GiveTask(TweenUtil.run(function(alpha)
                pizzaModel:PivotTo(pizzaStartCFrame:Lerp(pizzaEndCFrame, alpha))
            end, pizzaMoveTweenInfo))
        end

        -- Recipe
        do
            local pizzaNumber = totalPizzasMade + 1
            local recipeTypeLabel = recipeTypeOrder[totalPizzasMade + 1]
            local recipeType = PizzaMinigameConstants.RecipeTypes[recipeTypeLabel]
            local recipe = PizzaMinigameUtil.rollRecipe(pizzaNumber, recipeType)

            order:SetRecipe(recipe)
        end

        -- EDGE CASE: Time expired!
        local cachedTotalPizzas = totalPizzasMade
        task.delay(pizzaTime, function()
            -- RETURN: Client has since moved onto a new pizza
            if cachedTotalPizzas ~= totalPizzasMade then
                return
            end

            print("time expired")

            pizzaUpdate(false)
        end)
    end

    local function tickRunner(_dt)
        -- Hitbox
        local raycastResult = RaycastUtil.raycastMouse({
            FilterDescendantsInstances = hitboxParts,
            FilterType = Enum.RaycastFilterType.Whitelist,
        }, RAYCAST_LENGTH)
        currentHitbox = raycastResult and raycastResult.Instance
    end

    local function processHitboxClick()
        local hitbox: BasePart = currentHitbox
        print("click", hitbox)
    end

    local function cursorDown()
        if currentHitbox then
            processHitboxClick()
        end
    end

    local function cursorUp()
        --todo
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function runner:Run()
        Output.doDebug(MinigameConstants.DoDebug, "Run")

        -- Init Members
        do
            -- Gameplay Folder
            gameplayFolder = Instance.new("Folder")
            gameplayFolder.Name = "Gameplay"
            gameplayFolder.Parent = minigameFolder

            -- OrderSign
            order = PizzaMinigameOrder.new(minigameFolder.OrderSign:FindFirstChildWhichIsA("SurfaceGui", true))

            -- HitboxParts
            for _, descendant in pairs(minigameFolder.Hitboxes:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    table.insert(hitboxParts, descendant)
                end
            end
        end

        -- Setup Frame Updates
        maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
            tickRunner(dt)
        end))

        -- MouseFollowing
        maid:GiveTask(CameraController.followMouse(CAMERA_SWAY_MAX_ANGLE, CAMERA_SWAY_MAX_ANGLE))

        -- Cursor Input
        InputController.CursorDown:Connect(cursorDown)
        InputController.CursorUp:Connect(cursorUp)

        -- Start the gameplay loop!
        sendPizza()
    end

    function runner:Stop()
        Output.doDebug(MinigameConstants.DoDebug, "Stop")

        maid:Destroy()
    end

    return runner
end

return PizzaMinigameRunner
