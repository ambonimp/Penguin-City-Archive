--[[
    Class that represents an ingredient the client is currently holding. Can feedback to the runner.
]]
local PizzaMinigameIngredient = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local Output = require(Paths.Shared.Output)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Sound = require(Paths.Shared.Sound)

local RAYCAST_LENGTH = 100
local INGREDIENT_OFFSET = Vector3.new(0, 2, 0)
local PIZZA_INGREDIENT_OFFSET = Vector3.new(0, 0, 0)
local PROPERTIES = {
    ALIGN_POSITION = {
        MaxForce = 100000,
        MaxVelocity = math.huge,
        Responsiveness = 100,
    },
    ALIGN_ORIENTATION = {
        MaxTorque = 100000,
        MaxAngularVelocity = math.huge,
        Responsiveness = 100,
    },
    GOAL_PART = {
        Anchored = true,
        CanCollide = false,
        Size = Vector3.new(1, 1, 1),
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 1,
    },
}
local DESTROY_ASSET_AFTER = 3
local SHOW_ASSET_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local THROW_ASSET_POWER = {
    ANGULAR = 6,
    LINEAR = 22,
}
local THROW_EPSILON = 0.1
local BASE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FADE_INGREDIENT_SOUND_DURATION = 0.1

type PizzaMinigameRunner = typeof(require(Paths.Client.Minigames.Pizza.PizzaMinigameRunner).new(Instance.new("Folder"), {}, function() end))

function PizzaMinigameIngredient.new(runner: PizzaMinigameRunner, ingredientType: string, ingredientName: string, hitbox: BasePart)
    local ingredient = {}
    Output.doDebug(MinigameConstants.DoDebug, "new")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local asset: Model = runner:GetMinigameFolder().Assets[ingredientName]:Clone()
    local assetAttachment = Instance.new("Attachment")
    local alignPosition = Instance.new("AlignPosition")
    local alignOrientation = Instance.new("AlignOrientation")
    local goalAttachment = Instance.new("Attachment")
    local goalPart = Instance.new("Part")

    local assetHeightOffset = Vector3.new(0, asset.PrimaryPart.Size.Y / 2, 0)
    local isSauce = ingredientType == PizzaMinigameConstants.IngredientTypes.Sauces

    local isFirstRaycast = true
    local isPlaced = false
    local isOnPizza = false

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    --[[
        Converts the asset from an anchored model to a physics object, moveable by moving our `goalPart`
    ]]
    local function setup()
        -- Asset
        ModelUtil.unanchor(asset)
        ModelUtil.weld(asset)
        ModelUtil.hide(asset)
        assetAttachment.Parent = asset.PrimaryPart
        asset.Parent = runner:GetGameplayFolder()

        -- GoalPart
        InstanceUtil.setProperties(goalPart, PROPERTIES.GOAL_PART)
        goalPart.Parent = runner:GetGameplayFolder()
        goalAttachment.Parent = goalPart

        -- AlignPosition
        InstanceUtil.setProperties(alignPosition, PROPERTIES.ALIGN_POSITION)
        alignPosition.Attachment0 = assetAttachment
        alignPosition.Attachment1 = goalAttachment
        alignPosition.Parent = asset.PrimaryPart

        -- AlignOrientation
        InstanceUtil.setProperties(alignOrientation, PROPERTIES.ALIGN_ORIENTATION)
        alignOrientation.Attachment0 = assetAttachment
        alignOrientation.Attachment1 = goalAttachment
        alignOrientation.Parent = asset.PrimaryPart

        -- Sauces
        if ingredientType == PizzaMinigameConstants.IngredientTypes.Sauces then
            -- Randomly Offset SauceParticles
            for _, descendant: ParticleEmitter in pairs(asset:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") then
                    descendant.Enabled = false
                    task.delay(math.random() / descendant.Rate, function()
                        descendant.Enabled = true
                    end)
                end
            end

            -- Sound
            local ingredientSound = Sound.play(ingredientName, true)
            maid:GiveTask(function()
                Sound.fadeOut(ingredientSound, FADE_INGREDIENT_SOUND_DURATION, true)
            end)
        end
    end

    local function tickIngredient(_dt: number)
        -- Raycast where user is pointing
        local pizzaModel = runner:GetCurrentPizzaModel()
        local ingredients: Model = pizzaModel and pizzaModel.Ingredients
        local raycastResult = RaycastUtil.raycastMouse({
            FilterDescendantsInstances = { asset, goalPart, ingredients },
            FilterType = Enum.RaycastFilterType.Blacklist,
        }, RAYCAST_LENGTH)

        -- RETURN: No result
        if not raycastResult then
            return
        end

        -- EDGE CASE: First raycast! Init some stuff.
        if isFirstRaycast then
            isFirstRaycast = false

            asset:PivotTo(hitbox.CFrame)
            ModelUtil.show(asset, SHOW_ASSET_TWEEN_INFO)
        end

        -- Calculate new position
        isOnPizza = pizzaModel and pizzaModel:IsDescendantOf(game.Workspace) and raycastResult.Instance:IsDescendantOf(pizzaModel) and true
            or false
        local offset = (isOnPizza and not isSauce and PIZZA_INGREDIENT_OFFSET or INGREDIENT_OFFSET) + assetHeightOffset
        local newPosition = raycastResult.Position + offset

        -- Move
        goalPart.Position = newPosition

        -- EDGE CASE: Apply sauce
        if isSauce and isOnPizza and pizzaModel then
            -- Raycast for just sauce parts
            local sauceRaycastResult = RaycastUtil.raycastMouse({
                FilterDescendantsInstances = { pizzaModel.Sauce },
                FilterType = Enum.RaycastFilterType.Whitelist,
            }, RAYCAST_LENGTH)

            if sauceRaycastResult then
                runner:ApplySauce(ingredientName, sauceRaycastResult.Instance)
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function ingredient:GetName()
        return ingredientName
    end

    function ingredient:GetType()
        return ingredientType
    end

    --[[
        Whether the ingredient is currently positioned ontop the pizza or not
    ]]
    function ingredient:IsOnPizza()
        return isOnPizza
    end

    function ingredient:IsPlaced()
        return isPlaced
    end

    function ingredient:CanPlace()
        return not ingredient:IsPlaced() and not (ingredientType == PizzaMinigameConstants.IngredientTypes.Sauces)
    end

    function ingredient:Place()
        -- ERROR: Cannot place
        if not ingredient:CanPlace() then
            warn(("Cannot place %s (%s)!"):format(ingredientName, ingredientType))
            return
        end

        -- WARN: Already placed!
        if isPlaced then
            warn("Already placed!")
            return
        end
        isPlaced = true

        -- RETURN: No pizza model right now
        local pizzaModel = runner:GetCurrentPizzaModel()
        if not pizzaModel then
            return
        end

        -- Place onto Pizza
        ModelUtil.anchor(asset)
        asset.Parent = pizzaModel.Ingredients

        if ingredientType == PizzaMinigameConstants.IngredientTypes.Bases then
            -- WARN: Only supports single-part Bases at time of writing (sorry developer!)
            if #asset:GetChildren() > 1 then
                warn("No current support for multi-part Bases")
            end

            -- Cover pizza with the base
            local pizzaBase: BasePart = pizzaModel.Base
            local sizeFactor = pizzaBase.Size.X / asset.PrimaryPart.Size.X
            local primaryPart = asset.PrimaryPart
            local startSize = primaryPart.Size
            local goalSize = startSize * sizeFactor
            TweenUtil.run(function(alpha)
                primaryPart.Size = startSize:Lerp(goalSize, alpha)
                primaryPart.Position = primaryPart.Position:Lerp(pizzaBase.Position, alpha)
            end, BASE_TWEEN_INFO)
        elseif ingredientType == PizzaMinigameConstants.IngredientTypes.Toppings then
            -- Ensure topping is on the pizza (may get prematurely anchored if the player is very quick)
            asset:PivotTo(goalPart.CFrame)
        end
    end

    function ingredient:Destroy()
        Output.doDebug(MinigameConstants.DoDebug, "destroy")
        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()

    -- Pickup Audio feedback
    Sound.play("IngredientPickup")

    -- Cleanup
    do
        maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
            tickIngredient(dt)
        end))
        maid:GiveTask(goalPart)
        maid:GiveTask(function()
            -- RETURN: Asset was used to place on pizza
            if isPlaced then
                return
            end

            -- Throw asset
            local angularVelocity = VectorUtil.nextVector3(-1, 1).Unit * THROW_ASSET_POWER.ANGULAR
            local linearVelocity = Vector3.new(MathUtil.nextNumber(-1, 1), 8, MathUtil.nextNumber(-1, 1)).Unit * THROW_ASSET_POWER.LINEAR

            asset.PrimaryPart.AssemblyAngularVelocity = angularVelocity

            if asset.PrimaryPart.AssemblyLinearVelocity.Magnitude < THROW_EPSILON then
                asset.PrimaryPart.AssemblyLinearVelocity = linearVelocity
            end

            task.delay(DESTROY_ASSET_AFTER, function()
                asset:Destroy()
            end)
        end)
    end

    return ingredient
end

return PizzaMinigameIngredient
