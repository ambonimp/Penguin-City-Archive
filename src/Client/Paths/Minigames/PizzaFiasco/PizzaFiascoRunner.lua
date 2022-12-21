--[[
    This is a class that represents one "playthrough" of the pizza minigame (i.e., when they hit play, it creates a runner. when the game stops, the runner is destroyed).
    This handles everything in-game.

    We have a PizzaFiascoOrder, which has a 1-1 relationship with a PizzaFiascoRunner (handles the order board + tracks our ingredients on the current pizza)
    We have a PizzaFiascoIngredient, which has a many-1 relationship with a PizzaFiascoRunner (PizzaFiascoIngredient is created each time we pick up an ingredient)
]]
local PizzaFiascoRunner = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Shared.Maid)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local CameraController = require(Paths.Client.CameraController)
local InputController = require(Paths.Client.Input.InputController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PizzaFiascoConstants = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoConstants)
local PizzaFiascoUtil = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoUtil)
local PizzaFiascoOrder = require(Paths.Client.Minigames.PizzaFiasco.PizzaFiascoOrder)
local PizzaFiascoIngredient = require(Paths.Client.Minigames.PizzaFiasco.PizzaFiascoIngredient)
local Output = require(Paths.Shared.Output)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Remotes = require(Paths.Shared.Remotes)
local Sound = require(Paths.Shared.Sound)
local CoyoteTimeValue = require(Paths.Shared.CoyoteTimeValue)
local AnimationUtil = require(Paths.Shared.Utils.AnimationUtil)

local RAYCAST_LENGTH = 100
local CAMERA_SWAY_MAX_ANGLE = 2
local ADD_SAUCE_MIN_PROPORTION = 0.9
local SAUCE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
local STAGGER_SAUCE_AUTOFILL_BY = 0.25
local OLD_PIZZA_SPEED_FACTOR = 15
local MOVE_NEXT_PIZZA_AFTER = 0.5
local SPEED_UP_MUSIC_BY = 0.01
local DO_DEBUG_HITBOX = false
local HITBOX_COYOTE_TIME = 0.1
local CONVEYOR_TWEEN_INFOS = {
    TileV = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge),
}

local CONVEYOR_REVERSES = {
    TileV = true,
}
local FADE_MUSIC_DURATION = 1
local RUNNING_WATER_DURATION = 3

local assets = ReplicatedStorage.Assets.Minigames.PizzaFiasco

function PizzaFiascoRunner.new(map: Model, recipeTypeOrder: { string }, finishCallback: () -> nil)
    local runner = {}
    Output.doDebug(MinigameConstants.DoDebug, "new")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    local maid = Maid.new()
    local pizzaMaid = Maid.new()
    local cursorDownMaid = Maid.new()
    maid:GiveTask(pizzaMaid)
    maid:GiveTask(cursorDownMaid)

    local gameplayFolder: Folder
    local order: typeof(PizzaFiascoOrder.new(Instance.new("SurfaceGui")))
    local ingredient: typeof(PizzaFiascoIngredient.new(runner, "", "", Instance.new("Part"))) | nil
    local music = Sound.play("PizzaFiasco", true)

    local currentHitbox = CoyoteTimeValue.new()
    local hitboxParts: { BasePart } = {}
    local isRunning = false

    local pizzaLine: BasePart = map.Guides.PizzaLine
    local pizzaStartCFrame = CFrame.new(pizzaLine.Position - (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))
    local pizzaEndCFrame = CFrame.new(pizzaLine.Position + (pizzaLine.CFrame.LookVector * pizzaLine.Size.Z / 2))

    local totalPizzasMade = 0
    local totalMistakes = 0
    local totalCorrectPizzasInARow = 0
    local totalCoinsEarnt = 0

    local hasEnabledHeartPizza = false
    local hasSentHeartPizza = false

    -- These members dynamically change on each new sendPizza() call
    local recipe: PizzaFiascoUtil.Recipe
    local pizzaModel: Model?
    local isHeartPizza = false
    local appliedSauceParts: { [BasePart]: boolean } = {}
    local maxSauceParts: number

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local sendPizza: () -> nil -- Hoist this function
    -- Client has just finished a pizza
    local function pizzaUpdate(didComplete: boolean)
        Output.doDebug(MinigameConstants.DoDebug, "pizzaUpdate")

        -- SECRET: Heart pizza
        local doSubtractMistake = false
        if isHeartPizza then
            local noSauce = TableUtil.isEmpty(appliedSauceParts)

            local noIngredients = true
            for _, orderEntry in pairs(order:GetCurrentOrder()) do
                if orderEntry.Current > 0 then
                    noIngredients = false
                    break
                end
            end

            if noSauce and noIngredients then
                print("SUBTRACT MISTAKE!")
                doSubtractMistake = true
            end
        end

        -- Clear current pizzaModel
        pizzaModel = nil

        -- Update Internal counts
        totalPizzasMade += 1
        if doSubtractMistake then
            didComplete = true --!! Overrides didComplete
            totalMistakes -= 1
        end

        if didComplete then
            totalCoinsEarnt += PizzaFiascoUtil.calculatePizzaReward(totalPizzasMade)
            totalCorrectPizzasInARow += 1
        else
            totalMistakes += 1
            totalCorrectPizzasInARow = 0
        end

        -- Audio Feedback
        local soundName = doSubtractMistake and "ExtraLife" or didComplete and "CorrectPizza" or "WrongPizza"
        Sound.play(soundName)
        if didComplete then
            music.PlaybackSpeed = 1 + math.min(totalCorrectPizzasInARow, PizzaFiascoConstants.Conveyor.MaxIncreases) * SPEED_UP_MUSIC_BY
        else
            music.PlaybackSpeed = 1
        end

        Remotes.fireServer("PizzaFiascoPizzaCompleted", didComplete, doSubtractMistake)

        -- GAME FINISHED
        if totalPizzasMade == PizzaFiascoConstants.MaxPizzas or totalMistakes >= PizzaFiascoConstants.MaxMistakes then
            finishCallback()
            return
        end

        -- Update Orders
        order:SetCoinsEarnt(totalCoinsEarnt)
        order:SetPizzaCounts(totalPizzasMade, totalMistakes)

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
            local pizzaTime = PizzaFiascoConstants.Conveyor.Time
                * (
                    PizzaFiascoConstants.Conveyor.IncreaseFactor
                    ^ math.min(totalCorrectPizzasInARow, PizzaFiascoConstants.Conveyor.MaxIncreases)
                )
            do
                -- Place Pizza Model
                local thisPizzaModel = assets.Pizza:Clone()
                thisPizzaModel:PivotTo(pizzaStartCFrame)
                thisPizzaModel.Parent = gameplayFolder
                pizzaModel = thisPizzaModel

                -- SECRET: Heart pizza
                if hasEnabledHeartPizza and not hasSentHeartPizza then
                    hasSentHeartPizza = true

                    isHeartPizza = true
                    pizzaMaid:GiveTask(function()
                        isHeartPizza = false
                    end)

                    thisPizzaModel.Heart.Decal.Transparency = 0
                end

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

                local recipeType = PizzaFiascoConstants.RecipeTypes[recipeTypeLabel]
                recipe = PizzaFiascoUtil.rollRecipe(pizzaNumber, recipeType)

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

        -- Audio feedback
        Sound.play("IngredientPlace")

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

        local hitHitbox: BasePart = raycastResult and raycastResult.Instance
        if hitHitbox ~= currentHitbox:GetValue() then
            if DO_DEBUG_HITBOX then
                if currentHitbox:GetValue() then
                    currentHitbox:GetValue().Transparency = 1
                end
                if hitHitbox then
                    hitHitbox.Transparency = 0.5
                end
            end

            currentHitbox:SetValue(hitHitbox)
        end
    end

    local function setSinkSecretEnabled(doEnable: boolean)
        for _, particleEmitter: ParticleEmitter in pairs(map.Secrets.SinkParticle:GetDescendants()) do
            if particleEmitter:IsA("ParticleEmitter") then
                particleEmitter.Enabled = doEnable
            end
        end

        if doEnable then
            local runningWaterSound = Sound.play("RunningWater", true)
            task.delay(RUNNING_WATER_DURATION, function()
                if runningWaterSound.Parent and runningWaterSound.IsPlaying then
                    Sound.fadeOut(runningWaterSound, nil, true)
                end
            end)
            maid:GiveTask(runningWaterSound)
        end
    end

    local function setFireExtinguisherEnabled(doEnable: boolean)
        hasEnabledHeartPizza = doEnable
    end

    local function processHitboxClick()
        Output.doDebug(MinigameConstants.DoDebug, "hitboxClick", currentHitbox)

        local hitbox: BasePart = currentHitbox:GetValue()
        local isIngredient = hitbox:IsDescendantOf(map.Hitboxes.Ingredients)
        local isSecret = hitbox:IsDescendantOf(map.Hitboxes.Secrets)

        if isIngredient then
            -- ERROR: Unknown ingredient type
            local ingredientType = hitbox.Parent.Name
            if not PizzaFiascoConstants.IngredientTypes[ingredientType] then
                error(("Unknown ingredient type %s (%s)"):format(ingredientType, hitbox:GetFullName()))
            end

            -- ERROR: Unknown ingredient name
            local ingredientName = hitbox.Name
            if not PizzaFiascoConstants.Ingredients[ingredientType][ingredientName] then
                error(("Unknown ingredient name %s (%s)"):format(ingredientName, hitbox:GetFullName()))
            end

            -- EDGE CASE: Clean up old ingredient
            if ingredient then
                ingredient:Destroy()
                ingredient = nil
            end

            ingredient = PizzaFiascoIngredient.new(runner, ingredientType, ingredientName, hitbox)
            return
        end

        if isSecret then
            if hitbox.Name == "Sink" then
                setSinkSecretEnabled(true)
                return
            end
            if hitbox.Name == "FireExtinguisher" then
                setFireExtinguisherEnabled(true)
                return
            end
        end

        error(("Missing edgecase for hitbox %s"):format(hitbox:GetFullName()))
    end

    local function cursorDown(gameProcessedEvent)
        -- RETURN: Clicked something else
        if gameProcessedEvent then
            return
        end
        cursorDownMaid:GiveTask(currentHitbox:CallbackNonNil(processHitboxClick, HITBOX_COYOTE_TIME))
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

        cursorDownMaid:Cleanup()
    end

    local function tweenSaucePart(sauceColor: Color3, saucePart: BasePart)
        saucePart.Color = sauceColor

        local sauceSize = saucePart.Size
        saucePart.Size = Vector3.new(0, 0, 0)
        saucePart.Transparency = 0
        TweenUtil.tween(saucePart, SAUCE_TWEEN_INFO, { Size = sauceSize })
    end

    local function setIngredientLabelVisibility(isVisible: boolean)
        local labels = map:FindFirstChild("Labels")
        if labels then
            for _, surfaceGui: SurfaceGui in pairs(map.Labels:GetDescendants()) do
                if surfaceGui:IsA("SurfaceGui") then
                    surfaceGui.Enabled = isVisible
                end
            end
        end
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
            gameplayFolder = map:FindFirstChild("Gameplay") or Instance.new("Folder")
            gameplayFolder.Name = "Gameplay"
            gameplayFolder.Parent = map

            -- OrderSign
            order = PizzaFiascoOrder.new(map.OrderSign:FindFirstChildWhichIsA("SurfaceGui", true))

            -- HitboxParts
            for _, descendant in pairs(map.Hitboxes:GetDescendants()) do
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
        maid:GiveTask(InputController.CursorDown:Connect(cursorDown))
        maid:GiveTask(InputController.CursorUp:Connect(cursorUp))

        -- Ingredient Labels
        setIngredientLabelVisibility(true)

        -- Animate conveyor
        maid:GiveTask(AnimationUtil.animateTexture(map.ConveyorBelt.Top.Texture, CONVEYOR_TWEEN_INFOS, CONVEYOR_REVERSES))

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

    function runner:Getmap()
        return map
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
        local sauceAsset = assets[sauceName]
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
    maid:GiveTask(function()
        Sound.fadeOut(music, FADE_MUSIC_DURATION, true)
    end)

    -- One-time cleanups
    maid:GiveTask(function()
        if ingredient then
            ingredient:Destroy()
            ingredient = nil
        end
    end)

    -- Ingredient Labels
    maid:GiveTask(function()
        setIngredientLabelVisibility(false)
    end)

    -- Cleanup secrets
    maid:GiveTask(function()
        setSinkSecretEnabled(false)
        setFireExtinguisherEnabled(false)
    end)

    return runner
end

return PizzaFiascoRunner
