--[[
    Simple class for the water in our zones.

    Handles placement, movement, and stretching off to the horizon
]]
local WaterAnimator = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Maid = require(Paths.Shared.Maid)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local HORIZON_WIDTH = 100000
local PART_PROPERTIES = {
    SURFACE = {
        Transparency = 0.3,
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(248, 248, 248),
        Size = Vector3.new(2048, 0.5, 2048),
    },
    TEXTURE = {
        Transparency = 0.5,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(33, 84, 185),
        Size = Vector3.new(2048, 1.25, 2048),
    },
    MIDDLE = {
        Transparency = 0.7,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(27, 42, 53),
        Size = Vector3.new(2048, 0.5, 2048),
    },
    BOTTOM = {
        Transparency = 0.5,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(33, 84, 185),
        Size = Vector3.new(2048, 0.25, 2048),
    },
    HORIZON = {
        Transparency = 1, --!! Horizon is disabled for now, could not get it to look nice
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(33, 84, 185),
        Size = Vector3.new(1, 0.1, 1),
    },
}
local OFFSETS = {
    SURFACE = 0,
    TEXTURE = -0.675,
    MIDDLE = -1.55,
    BOTTOM = -1.925,
    HORIZON = -1.925,
}
local WATER_TEXTURE_PROPERTIES = {
    StudsPerTileU = 70,
    StudsPerTileV = 70,
    Texture = "rbxassetid://6126332496",
    Transparency = 0.8,
    Face = Enum.NormalId.Top,
}
local TIDE_MOVEMENT = {
    TWEEN_INFO = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    HEIGHT = 1.5,
    TEXTURE_OFFSET_PERCENT = 0.1,
}

local function createWaterPart(name: string, useMeshPart: boolean, keepSurfaceAppearance: boolean?)
    local part: MeshPart = useMeshPart and game.ReplicatedStorage.Assets.Misc.WaterMeshPart:Clone() or Instance.new("Part") -- Cannot assign MeshId by script :'c
    part.Name = name
    part.Size = Vector3.new(2048, 1, 2048)
    part.Anchored = true
    part.CanCollide = false

    if not keepSurfaceAppearance then
        local surfaceAppearance = part:FindFirstChildWhichIsA("SurfaceAppearance")
        if surfaceAppearance then
            surfaceAppearance:Destroy()
        end
    end

    return part
end

function WaterAnimator.new(xzPosition: Vector2, yTop: number)
    local waterAnimator = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    local waterModel = Instance.new("Model")
    waterModel.Name = "Water"
    waterModel.Parent = game.Workspace
    maid:GiveTask(waterModel)

    local surfacePosition = Vector3.new(xzPosition.X, yTop - PART_PROPERTIES.SURFACE.Size.Y / 2, xzPosition.Y)

    local surfacePart = createWaterPart("Surface", true, true)
    InstanceUtil.setProperties(surfacePart, PART_PROPERTIES.SURFACE)
    surfacePart.Position = surfacePosition
    surfacePart.Parent = waterModel

    local texturePart = createWaterPart("Texture", true)
    InstanceUtil.setProperties(texturePart, PART_PROPERTIES.TEXTURE)
    texturePart.Position = surfacePosition + Vector3.new(0, OFFSETS.TEXTURE, 0)
    texturePart.Parent = waterModel

    local waterTexture = Instance.new("Texture")
    InstanceUtil.setProperties(waterTexture, WATER_TEXTURE_PROPERTIES)
    waterTexture.Parent = texturePart

    local middlePart = createWaterPart("Middle", true)
    InstanceUtil.setProperties(middlePart, PART_PROPERTIES.MIDDLE)
    middlePart.Position = surfacePosition + Vector3.new(0, OFFSETS.MIDDLE, 0)
    middlePart.Parent = waterModel

    local bottomPart = createWaterPart("Bottom", true)
    InstanceUtil.setProperties(bottomPart, PART_PROPERTIES.BOTTOM)
    bottomPart.Position = surfacePosition + Vector3.new(0, OFFSETS.BOTTOM, 0)
    bottomPart.Parent = waterModel

    local horizonPart = createWaterPart("Horizon", false)
    InstanceUtil.setProperties(horizonPart, PART_PROPERTIES.HORIZON)
    horizonPart.Position = surfacePosition + Vector3.new(0, OFFSETS.HORIZON, 0)
    horizonPart.Parent = waterModel

    local horizonMesh = Instance.new("BlockMesh")
    horizonMesh.Scale = Vector3.new(HORIZON_WIDTH, 1, HORIZON_WIDTH)
    horizonMesh.Parent = horizonPart

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setupWaveMovement()
        local waterOrigin, _waterSize = waterModel:GetBoundingBox()

        -- Height
        do
            local topPivot = waterOrigin + Vector3.new(0, TIDE_MOVEMENT.HEIGHT, 0)
            local bottomPivot = waterOrigin

            waterModel:PivotTo(bottomPivot)
            maid:GiveTask(TweenUtil.run(function(alpha)
                waterModel:PivotTo(bottomPivot:Lerp(topPivot, alpha))
            end, TIDE_MOVEMENT.TWEEN_INFO))
        end

        -- Texture (tween in a random direction each tide cycle)
        do
            local doLoop = true
            local connection: RBXScriptConnection
            task.spawn(function()
                while doLoop do
                    local unitDirection = VectorUtil.getUnit(Vector3Util.getXZComponents(Vector3Util.nextVector(-1, 1)))
                    connection = TweenUtil.run(function(alpha)
                        waterTexture.OffsetStudsU = unitDirection.X
                            * alpha
                            * waterTexture.StudsPerTileU
                            * TIDE_MOVEMENT.TEXTURE_OFFSET_PERCENT
                        waterTexture.OffsetStudsV = unitDirection.Z
                            * alpha
                            * waterTexture.StudsPerTileV
                            * TIDE_MOVEMENT.TEXTURE_OFFSET_PERCENT
                    end, TIDE_MOVEMENT.TWEEN_INFO)

                    task.wait(TIDE_MOVEMENT.TWEEN_INFO.Time * 2) -- Account for reverse
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)

            maid:GiveTask(function()
                doLoop = false
                if connection then
                    connection:Disconnect()
                end
            end)
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function waterAnimator:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setupWaveMovement()

    return waterAnimator
end

--[[
    If we find a water structure in `zoneModel`, sets it up as a zone water!
]]
function WaterAnimator.scanZoneModel(zoneModel: Model)
    local waterAnimatorModel: Model
    local taggedInstances = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.WaterAnimator)
    for _, taggedInstance in pairs(taggedInstances) do
        if taggedInstance:IsDescendantOf(zoneModel) then
            waterAnimatorModel = taggedInstance
            break
        end
    end

    if waterAnimatorModel then
        -- Read Size/Position
        local cframe, size = waterAnimatorModel:GetBoundingBox()
        local yTop = cframe.Position.Y + size.Y / 2
        local xzPosition = Vector2.new(cframe.Position.X, cframe.Position.Z)

        -- Hide
        ModelUtil.hide(waterAnimatorModel)

        -- Create WaterAnimator
        return WaterAnimator.new(xzPosition, yTop)
    end
end

return WaterAnimator
