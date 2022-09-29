local PizzaMinigameRunner = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local CameraController = require(Paths.Client.CameraController)
local InputController = require(Paths.Client.Input.InputController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Paths.Shared.Minigames.Pizza.PizzaMinigameUtil)
local PizzaMinigameOrder = require(Paths.Client.Minigames.Pizza.PizzaMinigameOrder)
local PizzaMinigameIngredient = require(Paths.Client.Minigames.Pizza.PizzaMinigameIngredient)
local Output = require(Paths.Shared.Output)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Remotes = require(Paths.Shared.Remotes)
local Sound = require(Paths.Shared.Sound)

local RAYCAST_LENGTH = 100
local CAMERA_SWAY_MAX_ANGLE = 4
local ADD_SAUCE_MIN_PROPORTION = 0.9
local SAUCE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
local STAGGER_SAUCE_AUTOFILL_BY = 0.25
local OLD_PIZZA_SPEED_FACTOR = 10
local MOVE_NEXT_PIZZA_AFTER = 0.5
local SPEED_UP_MUSIC_BY = 0.01

function PizzaMinigameRunner.new(minigameFolder: Folder, recipeTypeOrder: { string }, finishCallback: () -> nil)
    local runner = {}
    Output.doDebug(MinigameConstants.DoDebug, "new")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local pizzaMaid = Maid.new()
    maid:GiveTask(pizzaMaid)

    local gameplayFolder: Folder
    local order: typeof(PizzaMinigameOrder.new(Instance.new("SurfaceGui")))
    local ingredient: typeof(PizzaMinigameIngredient.new(runner, "", "", Instance.new("Part"))) | nil
    local music = Sound.play("PizzaMinigame", true)

    local currentHitbox: BasePart?
    local hitboxParts: { BasePart } = {}
    local isRunning = false

    local pizzaLine: BasePart = minigameFolder.Guides.PizzaLine
    local pizzaStartCFrame = CFrame.new(pizzaLine.Position - (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))
    local pizzaEndCFrame = CFrame.new(pizzaLine.Position + (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))

    local totalPizzasMade = 0
    local totalMistakes = 0
    local totalCorrectPizzasInARow = 0
    local totalCoinsEarnt = 0

    -- These members dynamically change on each new sendPizza() call
    local recipe: PizzaMinigameUtil.Recipe
    local pizzaModel: Model?
    local appliedSauceParts: { [BasePart]: boolean } = {}
    local maxSauceParts: number

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local sendPizza: () -> nil -- Hoist this function
    -- Client has just finished a pizza
    local function pizzaUpdate(didComplete: boolean)
        Output.doDebug(MinigameConstants.DoDebug, "pizzaUpdate")

        -- Clear current pizzaModel
        pizzaModel = nil

        -- Update Internal counts
        totalPizzasMade += 1
        if didComplete then
            totalCoinsEarnt += PizzaMinigameUtil.calculatePizzaReward(totalPizzasMade)
            totalCorrectPizzasInARow += 1
        else
            totalMistakes += 1
            totalCorrectPizzasInARow = 0
        end

        -- Audio Feedback
        local soundName = didComplete and "CorrectPizza" or "WrongPizza"
        Sound.play(soundName)
        if didComplete then
            music.PlaybackSpeed = 1 + math.min(totalCorrectPizzasInARow, PizzaMinigameConstants.Conveyor.MaxIncreases) * SPEED_UP_MUSIC_BY
        else
            music.PlaybackSpeed = 1
        end

        -- GAME FINISHED
        if totalPizzasMade == PizzaMinigameConstants.MaxPizzas or totalMistakes >= PizzaMinigameConstants.MaxMistakes then
            finishCallback()
            return
        end

        Remotes.fireServer("PizzaMinigameCompletedPizza", didComplete)

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

        -- Send new pizza after a delay
        task.delay(MOVE_NEXT_PIZZA_AFTER, function()
            -- RETURN: No longer running
            if not isRunning then
                return
            end

            -- Pizza Model
            local pizzaTime = PizzaMinigameConstants.Conveyor.Time
                * (
                    PizzaMinigameConstants.Conveyor.IncreaseFactor
                    ^ math.min(totalCorrectPizzasInARow, PizzaMinigameConstants.Conveyor.MaxIncreases)
                )
            do
                -- Place Pizza Model
                local thisPizzaModel = minigameFolder.Assets.Pizza:Clone()
                thisPizzaModel:PivotTo(pizzaStartCFrame)
                thisPizzaModel.Parent = gameplayFolder
                pizzaModel = thisPizzaModel

                -- Setup Pizza Model movement
                local pizzaMovementTimeElapsed = 0
                pizzaMaid:GiveTask(RunService.RenderStepped:Connect(function(dt)
                    -- RETURN: No pizzaModel!
                    if not pizzaModel then
                        return
                    end

                    pizzaMovementTimeElapsed += dt
                    local alpha = pizzaMovementTimeElapsed / pizzaTime
                    pizzaModel:PivotTo(pizzaStartCFrame:Lerp(pizzaEndCFrame, alpha))
                end))

                -- Setup movement when exiting the conveyor / pizza model is "destroyed"
                pizzaMaid:GiveTask(function()
                    local currentAlpha = pizzaMovementTimeElapsed / pizzaTime
                    local oldPizzaMovementTimeElapsed = 0
                    local steppedConnection: RBXScriptConnection
                    steppedConnection = RunService.RenderStepped:Connect(function(dt)
                        oldPizzaMovementTimeElapsed += dt
                        local oldAlpha = oldPizzaMovementTimeElapsed / pizzaTime
                        local alpha = currentAlpha + oldAlpha * math.exp(oldAlpha * OLD_PIZZA_SPEED_FACTOR)
                        thisPizzaModel:PivotTo(pizzaStartCFrame:Lerp(pizzaEndCFrame, alpha))

                        if alpha >= 1 then
                            steppedConnection:Disconnect()
                            thisPizzaModel:Destroy()
                        end
                    end)
                end)

                -- Reset other members
                maxSauceParts = #pizzaModel.Sauce:GetChildren()
                appliedSauceParts = {}
            end

            -- Recipe
            do
                local pizzaNumber = totalPizzasMade + 1

                -- UH OH: Ran out of recipe types
                local recipeTypeLabel = recipeTypeOrder[totalPizzasMade + 1]
                if not recipeTypeLabel then
                    warn(("Ran out of recipeTypes! PizzaNumber: %d"):format(pizzaNumber))
                    finishCallback()
                    return
                end

                local recipeType = PizzaMinigameConstants.RecipeTypes[recipeTypeLabel]
                recipe = PizzaMinigameUtil.rollRecipe(pizzaNumber, recipeType)

                order:SetRecipe(recipe)
            end

            -- EDGE CASE: Time expired!
            local cachedTotalPizzas = totalPizzasMade
            task.delay(pizzaTime, function()
                -- RETURN: Client has since moved onto a new pizza
                if cachedTotalPizzas ~= totalPizzasMade then
                    return
                end

                -- RETURN: This runner is dead
                if not isRunning then
                    return
                end

                print("time expired")

                pizzaUpdate(false)
            end)
        end)
    end

    local function placeIngredient()
        -- WARN: No ingredient!
        if not ingredient then
            warn("No ingredient!")
            return
        end

        -- Place
        if ingredient:CanPlace() then
            ingredient:Place()
        end

        -- Read current state of pizza, and make decisions accordingly
        local successfulAdd = order:IngredientAdded(ingredient:GetName())
        if successfulAdd then
            if order:IsOrderFulfilled() then
                pizzaUpdate(true)
            end
        else
            pizzaUpdate(false)
        end
    end

    local function tickRunner(_dt)
        -- Update current Hitbox
        local raycastResult = RaycastUtil.raycastMouse({
            FilterDescendantsInstances = hitboxParts,
            FilterType = Enum.RaycastFilterType.Whitelist,
        }, RAYCAST_LENGTH)
        currentHitbox = raycastResult and raycastResult.Instance
    end

    local function processHitboxClick()
        Output.doDebug(MinigameConstants.DoDebug, "hitboxClick", currentHitbox)

        local hitbox: BasePart = currentHitbox
        local isIngredient = hitbox:IsDescendantOf(minigameFolder.Hitboxes.Ingredients)
        local isSecret = hitbox:IsDescendantOf(minigameFolder.Hitboxes.Secrets)

        if isIngredient then
            -- ERROR: Unknown ingredient type
            local ingredientType = hitbox.Parent.Name
            if not PizzaMinigameConstants.IngredientTypes[ingredientType] then
                error(("Unknown ingredient type %s (%s)"):format(ingredientType, hitbox:GetFullName()))
            end

            -- ERROR: Unknown ingredient name
            local ingredientName = hitbox.Name
            if not PizzaMinigameConstants.Ingredients[ingredientType][ingredientName] then
                error(("Unknown ingredient name %s (%s)"):format(ingredientName, hitbox:GetFullName()))
            end

            -- EDGE CASE: Clean up old ingredient
            if ingredient then
                ingredient:Destroy()
                ingredient = nil
            end

            ingredient = PizzaMinigameIngredient.new(runner, ingredientType, ingredientName, hitbox)
            return
        end

        if isSecret then
            warn(("todo secret %s"):format(hitbox.Name))
            return
        end

        error("Missing edgecase for hitbox")
    end

    local function cursorDown()
        if currentHitbox then
            processHitboxClick()
        end
    end

    local function cursorUp()
        if ingredient then
            if ingredient:IsOnPizza() and ingredient:CanPlace() then
                placeIngredient()
            end

            if ingredient then
                ingredient:Destroy()
                ingredient = nil
            end
        end
    end

    local function tweenSaucePart(sauceColor: Color3, saucePart: BasePart)
        saucePart.Color = sauceColor

        local sauceSize = saucePart.Size
        saucePart.Size = Vector3.new(0, 0, 0)
        saucePart.Transparency = 0
        TweenUtil.tween(saucePart, SAUCE_TWEEN_INFO, { Size = sauceSize })
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function runner:Run()
        -- RETURN: Already running
        if isRunning then
            warn("Already running")
            return
        end
        isRunning = true

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
        -- RETURN: Not running
        if not isRunning then
            warn("Not running")
            return
        end
        isRunning = false

        Output.doDebug(MinigameConstants.DoDebug, "Stop")

        maid:Destroy()
    end

    function runner:GetMinigameFolder()
        return minigameFolder
    end

    function runner:GetGameplayFolder()
        return gameplayFolder
    end

    function runner:GetCurrentPizzaModel()
        return pizzaModel
    end

    function runner:GetStats()
        return {
            TotalPizzas = totalPizzasMade,
            TotalMistakes = totalMistakes,
            TotalCoins = totalCoinsEarnt,
        }
    end

    function runner:IsRunning()
        return isRunning
    end

    function runner:SetRecipeTypeOrder(newRecipeTypeOrder: { string })
        recipeTypeOrder = newRecipeTypeOrder
    end

    function runner:ApplySauce(sauceName: string, saucePart: BasePart)
        -- WARN: Not a descendant of current pizza!
        if not saucePart:IsDescendantOf(pizzaModel.Sauce) then
            warn(("Sauce part %s not on our current pizza"):format(saucePart:GetFullName()))
            return
        end

        -- RETURN: Already applied
        if appliedSauceParts[saucePart] then
            return
        end
        appliedSauceParts[saucePart] = true

        -- ERROR: Could not find a sauce emitter
        local sauceAsset = minigameFolder.Assets[sauceName]
        local sauceEmitter = sauceAsset:FindFirstChildWhichIsA("ParticleEmitter", true)
        if not sauceEmitter then
            error(("Could not find ParticleEmitter for sauce %s asset (%s)"):format(sauceName, sauceEmitter:GetFullName()))
        end

        -- Tween in sauce
        local sauceColor = sauceEmitter.Color.Keypoints[1].Value
        tweenSaucePart(sauceColor, saucePart)

        -- RETURN: Wrong sauce!
        if sauceName ~= recipe.Sauce then
            pizzaUpdate(false)
            return
        end

        -- Add sauce as completed!
        local totalAppliedSauceParts = TableUtil.length(appliedSauceParts)
        if totalAppliedSauceParts / maxSauceParts > ADD_SAUCE_MIN_PROPORTION then
            -- Tween other sauce parts
            for _, someSaucePart in pairs(pizzaModel.Sauce:GetChildren()) do
                if not appliedSauceParts[someSaucePart] then
                    appliedSauceParts[someSaucePart] = true
                    task.delay(math.random(0, STAGGER_SAUCE_AUTOFILL_BY), tweenSaucePart, sauceColor, someSaucePart)
                end
            end

            -- Place
            placeIngredient()
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Music
    maid:GiveTask(music)

    -- One-time cleanups
    maid:GiveTask(function()
        if ingredient then
            ingredient:Destroy()
            ingredient = nil
        end
    end)

    return runner
end

return PizzaMinigameRunner
