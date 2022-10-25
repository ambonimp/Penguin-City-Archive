--[[
    Essentially a class for vehicle handling except there can only one at a time, so no need to make it into one
]]
local VehicleUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.Shared
local VehicleConstants = require(Shared.Constants.VehicleConstants)
local VectorUtil = require(Shared.Utils.VectorUtil)

-- Float Spring
local FLOAT_STRENGTH = 350
local FLOAT_DAMPING = 2500
-- Little sine wave
local BUOYANCY_HEIGHT = 0.5
local BUOYANCY_RATE = 60 -- Every x secs, sine wave returns to 0
-- Distance above platform to cast raycasts from
local RAYCAST_HEIGHT = Vector3.new(0, 2, 0)
local PLATFORM_CORNERS = {
    Vector3.new(1, 0, 1),
    Vector3.new(1, 0, -1),
    Vector3.new(-1, 0, 1),
    Vector3.new(-1, 0, -1),
}

local move: Vector3?
local et: number?
local moveVelocity: Vector3?
local direction: { X: CFrame, Y: CFrame?, Z: CFrame }?
local raycastParams: RaycastParams?
local platform: BasePart?
local platformSize: Vector3?

-- Enums
local hoverHeight: number
local acceleration: number
local maxSpeed: number
local maxForce: number

-- 0 <= x <= 1. Smaller x's are made amplified
local function magnify(x: number): number
    local b = -0.01
    return math.sign(x) * (1 / math.log((b - 1) / b) * math.log((b - math.abs(x)) / b))
end

local function getSlope(axis: Vector3, magnitude: number): Vector3?
    local _, y, _ = platform.CFrame:ToEulerAnglesYXZ()
    local cframe = CFrame.new(platform.Position + RAYCAST_HEIGHT) * CFrame.fromEulerAnglesYXZ(0, y, 0)
    local rayDirection = Vector3.new(0, -magnitude, 0)

    axis *= Vector3.new(1, 1, -1)
    local r1 = workspace:Raycast(cframe:PointToWorldSpace(axis * platformSize), rayDirection, raycastParams)
    local r2 = workspace:Raycast(cframe:PointToWorldSpace(-axis * platformSize), rayDirection, raycastParams)

    if r1 and r2 then
        return r1.Position - r2.Position
    end
end

function VehicleUtil.new(player: Player, model: Model)
    et = 0

    platform = model:WaitForChild("Platform")
    platformSize = platform.Size / 2

    moveVelocity = Vector3.new()
    direction = { X = CFrame.new(), Z = CFrame.new() }

    raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { player.Character, platform.Parent }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local enums = VehicleConstants[platform.Parent.Name]
    acceleration = enums.Acceleration
    maxSpeed = enums.MaxSpeed
    maxForce = enums.MaxForce
    hoverHeight = enums.HoverHeight
end

-- Mostly for garbage collection
function VehicleUtil.destroy()
    et = nil
    moveVelocity = nil
    raycastParams = nil

    direction = nil
end

function VehicleUtil.updateMove(input: Vector3)
    move = input
end

function VehicleUtil.getThrottle(): number
    return math.sign(move.Magnitude)
end

function VehicleUtil.applyFloatForce(dt: number)
    -- Only play bouncing animation when not moving
    if VehicleUtil.getThrottle() == 0 then
        et += dt
    end

    local bouyancyOffset = math.sin(et / (math.rad(BUOYANCY_RATE) / math.pi)) * BUOYANCY_HEIGHT

    local cframe = platform.CFrame
    local tallestFloorHeight = -math.huge

    local rayDirection = Vector3.new(0, -100, 0)
    for _, corner in pairs(PLATFORM_CORNERS) do
        local origin = cframe:PointToWorldSpace(platformSize * corner)
        tallestFloorHeight = math.max(tallestFloorHeight, Workspace:Raycast(origin, rayDirection, raycastParams).Position.Y)
    end

    local offset = math.max(-2.8, (tallestFloorHeight + hoverHeight + bouyancyOffset) - cframe.Position.Y)
    platform.Float.Force = Vector3.new(0, (offset * FLOAT_STRENGTH) - (platform.AssemblyLinearVelocity.Y * dt * FLOAT_DAMPING), 0)
        * platform.AssemblyMass
end

function VehicleUtil.applyMoveFoce(dt: number)
    local goalVelocity = (platform.Look.CFrame.LookVector) :: Vector3 * VehicleUtil.getThrottle() * maxSpeed
    local dV = (goalVelocity - moveVelocity) * acceleration * dt
    moveVelocity += dV

    local dA = (moveVelocity - platform.AssemblyLinearVelocity * Vector3.new(1, 0, 1)) / dt
    dA = VectorUtil.ifNanThen0(dA.Unit * math.min(dA.Magnitude, maxForce))

    platform.Move.Force = dA * platform.AssemblyMass
end

function VehicleUtil.updateDirection(dt: number, yaw: number, delyaYaw: number)
    -- Roll
    direction.Z = direction.Z:Lerp(CFrame.fromEulerAnglesYXZ(0, 0, magnify(delyaYaw / math.pi) * math.rad(35)), dt * 2)
    direction.Y = CFrame.fromEulerAnglesYXZ(0, yaw, 0)

    -- Pitch
    local slope = getSlope(Vector3.new(0, 0, 1), 15)
    if slope then
        slope = direction.Y:PointToObjectSpace(slope)

        local thetha = math.atan(math.max(slope.Y, -2) / -slope.Z)
        thetha = math.sign(thetha) * (if math.abs(thetha) < math.rad(hoverHeight * 4) then 0 else thetha)

        direction.X = direction.X:Lerp(CFrame.fromEulerAnglesYXZ(thetha, 0, 0), dt * (if thetha == 0 then 1 else 3.5))
    end

    platform.Look.CFrame = direction.X * direction.Y * direction.Z
end

return VehicleUtil
