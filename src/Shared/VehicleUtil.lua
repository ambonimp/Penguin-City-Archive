local Workspace = game:GetService("Workspace")

local VehicleUtil = {}

local VehicleEnums = require(script.Parent.Enums.Vehicles)

-- Float Spring
local FLOAT_STRENGTH = 350
local FLOAT_DAMPING = 2500

-- Little sine wave
local BUOYANCY_HEIGHT = 0.5
local BUOYANCY_RATE = 60 -- Every x secs, sine wave returns to 0

local RAYCAST_HEIGHT = Vector3.new(0, 2, 0) -- Distance above platform to cast raycasts from

local PLATFORM_CORNERS = {
    Vector3.new(0.5, 0, 0.5),
    Vector3.new(0.5, 0, -0.5),
    Vector3.new(-0.5, 0, 0.5),
    Vector3.new(-0.5, 0, -0.5),
}

local move

local et, moveVel, rot, raycastParams, platform, platformSize
local hoverHeight, accel, maxSpeed, maxForce

local function nanLess(x)
    return if x == x then x else Vector3.new()
end

-- 0 <= x <= 1. smaller x's are made amplified
local function magnify(x)
    local b = -0.01
    return math.sign(x) * (1 / math.log((b - 1) / b) * math.log((b - math.abs(x)) / b))
end

local function getSlope(axis, magnitude)
    local _, y, _ = platform.CFrame:ToEulerAnglesYXZ()
    local cframe = CFrame.new(platform.Position + RAYCAST_HEIGHT) * CFrame.fromEulerAnglesYXZ(0, y, 0)
    local dir = Vector3.new(0, -magnitude, 0)

    local r1 = workspace:Raycast(cframe:PointToWorldSpace(axis * Vector3.new(1, 1, -1) * platformSize), dir, raycastParams)
    local r2 = workspace:Raycast(cframe:PointToWorldSpace(-axis * Vector3.new(1, 1, -1) * platformSize), dir, raycastParams)

    if r1 and r2 then
        return r1.Position - r2.Position
    end
end

function VehicleUtil.new(player, model)
    et = 0

    platform = model.Platform
    platformSize = platform.Size / 2

    moveVel = Vector3.new()
    rot = { X = CFrame.new(), Z = CFrame.new() }

    raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { player.Character, platform.Parent }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local enums = VehicleEnums[platform.Parent.Name]
    accel = enums.Acceleration
    maxSpeed = enums.MaxSpeed
    maxForce = enums.MaxForce
    hoverHeight = enums.HoverHeight
end

-- Mostly for garbage collection
function VehicleUtil.destroy()
    et = nil
    moveVel = nil
    raycastParams = nil

    rot = nil
end

function VehicleUtil.updateMove(input)
    move = input
end

function VehicleUtil.getThrottle()
    return math.sign(move.Magnitude)
end

function VehicleUtil.applyFloatForce(dt)
    -- Only play slight bouncing animation when not moving
    if VehicleUtil.getThrottle() == 0 then
        et += dt
    end

    local bouyancyOffset = math.sin(et / (math.rad(BUOYANCY_RATE) / math.pi)) * BUOYANCY_HEIGHT

    local cf = platform.CFrame
    local tallestSurface = -math.huge
    for _, corner in PLATFORM_CORNERS do
        tallestSurface = math.max(
            tallestSurface,
            Workspace:Raycast(cf:PointToWorldSpace(platformSize * corner), Vector3.new(0, -100, 0), raycastParams).Position.Y
        )
    end

    local offset = math.max(-2.8, (tallestSurface + hoverHeight + bouyancyOffset) - cf.Position.Y)
    platform.Float.Force = Vector3.new(0, (offset * FLOAT_STRENGTH) - (platform.AssemblyLinearVelocity.Y * dt * FLOAT_DAMPING), 0)
        * platform.AssemblyMass
end

function VehicleUtil.applyMoveFoce(dt)
    local goalVel = platform.Look.CFrame.LookVector * VehicleUtil.getThrottle() * maxSpeed
    local dV = (goalVel - moveVel) * accel * dt
    moveVel += dV

    local dA = (moveVel - platform.Velocity * Vector3.new(1, 0, 1)) / dt
    dA = nanLess(dA.Unit * math.min(dA.Magnitude, maxForce))

    platform.Move.Force = dA * platform.AssemblyMass
end

function VehicleUtil.updateLook(dt, yaw, delyaYaw)
    -- Roll
    rot.Z = rot.Z:Lerp(CFrame.fromEulerAnglesYXZ(0, 0, magnify(delyaYaw / math.pi) * math.rad(35)), dt * 2)

    -- Pitch
    local slope = getSlope(Vector3.new(0, 0, 1), 15)
    if slope then
        local thetha = math.atan(math.max(slope.Y, -2) / -slope.Z)
        thetha = math.sign(thetha) * (if math.abs(thetha) < math.rad(hoverHeight * 4) then 0 else thetha)

        rot.X = rot.X:Lerp(CFrame.fromEulerAnglesXYZ(thetha, 0, 0), dt * (if thetha == 0 then 1 else 3.5))
    end

    platform.Look.CFrame = rot.X * CFrame.fromEulerAnglesYXZ(0, yaw, 0) * rot.Z
end

return VehicleUtil
