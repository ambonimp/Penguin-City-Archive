--[[
    Class that represents an ingredient the client is currently holding
]]
local PizzaMinigameIngredient = {}

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
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local RAYCAST_LENGTH = 100
local INGREDIENT_OFFSET = Vector3.new(0, 2, 0)
local PIZZA_INGREDIENT_OFFSET = Vector3.new(0, 0.5, 0)
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

type PizzaMinigameRunner = typeof(require(Paths.Client.Minigames.Pizza.PizzaMinigameRunner).new(Instance.new("Folder"), {}))

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
    local filterDescendantsInstances = { asset, goalPart }
    local isFirstRaycast = true

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

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
    end

    local function tickIngredient(_dt: number)
        -- Raycast where user is pointing
        local raycastResult = RaycastUtil.raycastMouse({
            FilterDescendantsInstances = filterDescendantsInstances,
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
        local isOnPizza = raycastResult.Instance:IsDescendantOf(runner:GetCurrentPizzaModel())
        local offset = (isOnPizza and not isSauce and PIZZA_INGREDIENT_OFFSET or INGREDIENT_OFFSET) + assetHeightOffset
        local newPosition = raycastResult.Position + offset

        -- Move
        goalPart.Position = newPosition
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function ingredient:Destroy()
        Output.doDebug(MinigameConstants.DoDebug, "destroy")
        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()

    -- Cleanup
    do
        maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
            tickIngredient(dt)
        end))
        maid:GiveTask(goalPart)
        maid:GiveTask(function()
            task.delay(DESTROY_ASSET_AFTER, function()
                asset:Destroy()
            end)
        end)
    end

    return ingredient
end

return PizzaMinigameIngredient
