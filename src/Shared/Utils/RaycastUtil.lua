local RaycastUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local BooleanUtil = require(ReplicatedStorage.Shared.Utils.BooleanUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

local DO_SHOW_RAYCASTS = false
local OFFSET_RAYCAST_EPSILON = 0.01

local internalRaycastParams = RaycastParams.new()

local Defaults = {
    CollisionGroup = "Default",
    FilterDescendantsInstances = {},
    FilterType = Enum.RaycastFilterType.Blacklist,
    IgnoreWater = false,
}

function RaycastUtil.raycastMouse(
    raycastParams: {
        CollisionGroup: string?,
        FilterDescendantsInstances: { Instance }?,
        FilterType: Enum.RaycastFilterType?,
        IgnoreWater: boolean?,
    }?,
    length: number?,
    check: ((instance: BasePart) -> boolean)?
): RaycastResult | nil
    -- RETURN: Client method
    if not RunService:IsClient() then
        error("Client only")
    end

    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = game.Workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

    return RaycastUtil.raycast(ray.Origin, ray.Direction, raycastParams, length, check)
end

--[[
    Quick wrapper for raycasting.
    - Reuses RaycastParams (is performatic)
    - Optional `length` if you don't want to encode the length of the raycast in `direction`
    - Optional `check`; when we hit an `Instance`, it must be such that `check(instance) == true` - otherwise, we raycast below it.
]]
function RaycastUtil.raycast(
    origin: Vector3,
    direction: Vector3,
    raycastParams: {
        CollisionGroup: string?,
        FilterDescendantsInstances: { Instance }?,
        FilterType: Enum.RaycastFilterType?,
        IgnoreWater: boolean?,
    }?,
    length: number?,
    check: ((instance: BasePart) -> boolean)?
): RaycastResult | nil
    raycastParams = raycastParams or {}

    internalRaycastParams.CollisionGroup = raycastParams.CollisionGroup or Defaults.CollisionGroup
    internalRaycastParams.FilterDescendantsInstances = raycastParams.FilterDescendantsInstances or Defaults.FilterDescendantsInstances
    internalRaycastParams.FilterType = raycastParams.FilterType or Defaults.FilterType
    internalRaycastParams.IgnoreWater = BooleanUtil.returnFirstBoolean(raycastParams.IgnoreWater, Defaults.IgnoreWater)

    if length then
        direction = direction.Unit * length
    end

    local raycastResult = game.Workspace:Raycast(origin, direction, internalRaycastParams)

    if DO_SHOW_RAYCASTS then
        DebugUtil.showRaycast(origin, direction, direction.Magnitude, raycastResult)
    end

    -- Check
    if check then
        if raycastResult and check(raycastResult.Instance) == false then
            -- Raycast below this failed Instance!
            local offsetLength = raycastResult.Distance + OFFSET_RAYCAST_EPSILON
            origin = origin + direction.Unit * offsetLength
            if length then
                length = math.max(length - offsetLength, 0)
            end

            return RaycastUtil.raycast(origin, direction, raycastParams, length, check)
        end
    end

    return raycastResult
end

return RaycastUtil
