local SledRaceDriving = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local CFrameUtil = require(Paths.Shared.Utils.CFrameUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local Toggle = require(Paths.Shared.Toggle)
local Lerpable = require(Paths.Shared.Lerpable)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)
local Sound = require(Paths.Shared.Sound)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local CollisionConstants = require(Paths.Shared.Constants.CollisionsConstants)

local MIN_SPEED = SledRaceConstants.MinSpeed
local DEFAULT_SPEED = SledRaceConstants.DefaultSpeed
local MAX_SPEED = SledRaceConstants.MaxSpeed
local SPEED_OFFSET_RANGE = math.min(DEFAULT_SPEED - MIN_SPEED, MAX_SPEED - DEFAULT_SPEED)
local ACCELERATION = SledRaceConstants.Acceleration
local MAX_FORCE = 1000

local BASE_FOV = 70
local MAX_DRIFT_FOV_MINUEND = -10
local MAX_SPEED_FOV_ADDEND = 20

local MAX_DRIFT_PARTICLE_RATE = 100
local MIN_DRIFT_PARTICLE_RATE = 2

local MAX_STEER_ANGLE = SledRaceConstants.MaxSteerAngle
local STEERING_GAINS = SledRaceConstants.SteeringControllerGains
local STEERING_KP = STEERING_GAINS.Kp
local STEERING_KD = STEERING_GAINS.Kd

local RAYCAST_DISTANCE = 50
local TOP_SURFACE = Vector3.new(0, -1, 0)

local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.CollisionGroup = CollisionConstants.Groups.Default

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local playerControls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local isSteeringControlled: typeof(Toggle.new(true))
local goalSpeed: number

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getOverlapRatio(part: BasePart, platforms: { BasePart }): { [BasePart]: number }
    if #platforms == 1 then
        return { [platforms[1]] = 1 }
    else
        local axis = "Z"

        local colliderPosition = BasePartUtil.getSurfacePosition(part, TOP_SURFACE)[axis]
        local colliderSize = BasePartUtil.getGlobalSurfaceExtentSize(part, TOP_SURFACE)[axis] / 2

        -- one is right of/infront and the other is left of/behind the mover
        local platformEdges = {}
        for _, platform in platforms do
            local position = platform.Position[axis]
            local directionToCenter = math.sign(colliderPosition - position) -- from platform

            -- first param: direction to center is reversed when the pov switches to the platform
            platformEdges[platform] = {
                -directionToCenter,
                position + directionToCenter * BasePartUtil.getGlobalExtentsSize(platform)[axis] / 2,
            }
        end

        local ratios = {}
        local ratiosTotal = 0
        for platform, info in platformEdges do
            local directionToPlatform = info[1]
            local platformEdge = info[2]

            local colliderEdge = colliderPosition + directionToPlatform * colliderSize
            local platformOverlap = math.max(0, -directionToPlatform * (platformEdge - colliderEdge))

            ratiosTotal += platformOverlap
            ratios[platform] = platformOverlap
        end

        for platform, ratio in ratios do
            ratios[platform] = ratio / ratiosTotal
        end

        return ratios
    end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SledRaceDriving.setup()
    local character = player.Character

    local map = MinigameController.getMap()
    local mapDirection: CFrame = SledRaceUtil.getMapOrigin(map).Rotation

    local sled: Model = SledRaceUtil.getSled(player)
    local physicsPart: BasePart = sled:WaitForChild("Physics")

    local move: VectorForce = physicsPart.Move
    local alignOrientation: AlignOrientation = physicsPart.AlignOrientation

    local idealVelocity = Vector3.new()
    goalSpeed = DEFAULT_SPEED

    local forcedSpeed
    local forcedAcceleration

    local steerPreError = 0
    local steerControl = 1
    isSteeringControlled = Toggle.new(true, function(value)
        if value then
            steerControl = 1
        else
            steerControl = 0.5
        end
    end)

    local driftParticles = {}
    local driftParticleRate = Lerpable.new(0, 10)

    local driftFOVAddend = Lerpable.new(0)
    local speedFOVAddend = Lerpable.new(0)

    local drivingSound: Sound = Sound.play("SledMovement", true)

    for _, particle in ipairs(sled:GetDescendants()) do
        if particle:IsA("ParticleEmitter") then
            table.insert(driftParticles, particle)
        end
    end

    local controlling: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
        local sledCFrame: CFrame = physicsPart.CFrame
        local mass = physicsPart.AssemblyMass
        local input = playerControls:GetMoveVector()

        do
            -- Yaw
            local err = ((MAX_STEER_ANGLE * -input.X) - CFrameUtil.yComponent(mapDirection:ToObjectSpace(sledCFrame)))
            local delta = (err - steerPreError)
            steerPreError = err

            local proportionalOutput = err * STEERING_KP
            local derrivativeOutput = delta / dt * STEERING_KD * steerControl
            local yaw = math.clamp(proportionalOutput + derrivativeOutput, -MAX_STEER_ANGLE, MAX_STEER_ANGLE)

            -- Pitch
            local platforms = {}
            local inclines = {}
            for i = 1, 2 do
                local raycastResult = Workspace:Raycast(
                    sledCFrame * Vector3.new(0, 0, (if i == 1 then 1 else -1) * physicsPart.Size.Z / 2),
                    -sledCFrame.UpVector * RAYCAST_DISTANCE,
                    RAYCAST_PARAMS
                )

                if raycastResult then
                    local platform = raycastResult.Instance
                    if not table.find(platforms, platform) then
                        table.insert(platforms, platform)
                        inclines[platform] = Vector3.fromAxis(Enum.Axis.Y):Angle(raycastResult.Normal, mapDirection.RightVector)
                    end
                end
            end

            local overlapRatios = getOverlapRatio(physicsPart, platforms)
            local pitch = 0
            for _, platform in platforms do
                pitch += overlapRatios[platform] * inclines[platform]
            end

            local cframe = mapDirection * CFrame.Angles(pitch, yaw, 0)
            alignOrientation.CFrame = cframe
        end

        -- Moving
        do
            local goalVelocity = sledCFrame.LookVector * (forcedSpeed or goalSpeed)
            local deltaVelocity = (goalVelocity - idealVelocity) * (forcedAcceleration or ACCELERATION) * dt
            idealVelocity += deltaVelocity

            local acceleration: Vector3 = (idealVelocity - physicsPart.AssemblyLinearVelocity) / dt * Vector3.new(1, 0, 1)
            acceleration = Vector3Util.ifNanThen0(acceleration.Unit * math.min(acceleration.Magnitude, MAX_FORCE))
            move.Force = acceleration * mass
        end

        -- Effects
        do
            local driftyness = math.min(1, math.abs(CFrameUtil.yComponent(mapDirection:ToObjectSpace(sledCFrame))) / MAX_STEER_ANGLE) -- How not forward is the sled
            local speedyness = math.clamp((goalSpeed - DEFAULT_SPEED) / SPEED_OFFSET_RANGE, -1, 1) -- speed vs default speed deviation percentage

            for _, emitter in pairs(driftParticles) do
                emitter.Rate = driftParticleRate:UpdateVariable(
                    math.max(MIN_DRIFT_PARTICLE_RATE, MAX_DRIFT_PARTICLE_RATE * driftyness * MathUtil.map(speedyness, -1, 1, 0, 1)),
                    dt * 5
                )
            end

            camera.FieldOfView = BASE_FOV
                + driftFOVAddend:UpdateVariable(-MAX_DRIFT_FOV_MINUEND * driftyness, dt * 5)
                + speedFOVAddend:UpdateVariable(MAX_SPEED_FOV_ADDEND * math.max(0, speedyness), dt * 3)

            drivingSound.PlaybackSpeed = 1 + speedyness
        end
    end)

    local complete: RBXScriptConnection?
    complete = map.Course.Finish.FinishLine.Detection.Touched:Connect(function(hit)
        if hit:IsDescendantOf(character) then
            complete:Disconnect()
            complete = nil

            local physicalProperties = physicsPart.CustomPhysicalProperties
            physicsPart.CustomPhysicalProperties = PhysicalProperties.new(
                3,
                1, -- friction
                physicalProperties.Elasticity,
                physicalProperties.FrictionWeight,
                physicalProperties.ElasticityWeight
            )

            Sound.fadeOut(drivingSound)

            forcedAcceleration = 1
            forcedSpeed = 0

            Confetti.play()
        end
    end)

    -- Goo
    SledRaceUtil.unanchorSled(player)

    return function()
        controlling:Disconnect()
        drivingSound:Destroy()

        if complete then
            complete:Disconnect()
        end

        playerControls:Enable()
    end
end

function SledRaceDriving.disableControlledSteering(scope: any, durationFactor: number)
    isSteeringControlled:Set(false, scope)

    -- reverse effects
    task.delay(SledRaceConstants.CollectableEffectDuration * durationFactor, function()
        isSteeringControlled:Set(true, scope)
    end)
end

function SledRaceDriving.applySpeedModifier(addend: number)
    goalSpeed = math.clamp(goalSpeed + addend, SledRaceConstants.MinSpeed, SledRaceConstants.MaxSpeed)

    -- reverse effects
    task.delay(SledRaceConstants.CollectableEffectDuration, function()
        goalSpeed = math.clamp(goalSpeed - addend, SledRaceConstants.MinSpeed, SledRaceConstants.MaxSpeed)
    end)
end

return SledRaceDriving
