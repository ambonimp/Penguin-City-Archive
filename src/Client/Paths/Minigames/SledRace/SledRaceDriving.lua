local SledRaceDriving = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local MIN_SPEED = SledRaceConstants.MinSpeed
local DEFAULT_SPEED = SledRaceConstants.DefaultSpeed
local MAX_SPEED = SledRaceConstants.MaxSpeed
local SPEED_OFFSET_RANGE = math.min(DEFAULT_SPEED - MIN_SPEED, MAX_SPEED - DEFAULT_SPEED)
local ACCELERATION = SledRaceConstants.Acceleration

local STEERING_GAINS = SledRaceConstants.SteeringControllerGains
local STEERING_Kp = STEERING_GAINS.Kp
local STEERING_Kd = STEERING_GAINS.Kd

local MAX_STEER_ANGLE = SledRaceConstants.MaxSteerAngle
local MAX_SEAT_LEAN_ANGLE = math.rad(75)

local MAX_FORCE = 1000
local MAX_ANGULAR_ALIGNMENT_TORQUE = 9000
local MAX_STEER_TORQUE = 400

local BASE_FOV = 70
local MAX_DRIFT_FOV_MINUEND = -10
local MAX_SPEED_FOV_ADDEND = 20

local MAX_DRIFT_PARTICLE_RATE = 100
local MIN_DRIFT_PARTICLE_RATE = 2

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local playerControls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local isSteeringControlled: typeof(Toggle.new(true))
local goalSpeed: number

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SledRaceDriving.setup()
    local character = player.Character
    local tailbone = character.Body.Main_Bone
    local seatingCFrame: CFrame = tailbone.CFrame

    local map = MinigameController.getMap()
    local mapDirection: CFrame = SledRaceUtil.getMapOrigin(map).Rotation

    local sled: Model = SledRaceUtil.getSled(player)
    local physicsPart: BasePart = sled:WaitForChild("Physics")

    local move: VectorForce = physicsPart.Move
    local steer: Torque = physicsPart.Steer
    local alignRotation: AngularVelocity = physicsPart.AlignRotation

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

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    for _, particle in ipairs(sled:GetDescendants()) do
        if particle:IsA("ParticleEmitter") then
            table.insert(driftParticles, particle)
        end
    end

    local driving: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
        local sledCFrame: CFrame = physicsPart.CFrame
        local mass = physicsPart.AssemblyMass
        local input = playerControls:GetMoveVector()

        -- Steering
        do
            local direction = -input.X

            local err = ((MAX_STEER_ANGLE * direction) - CFrameUtil.yComponent(mapDirection:ToObjectSpace(sledCFrame)))
            local delta = (err - steerPreError)
            steerPreError = err

            local proportionalOutput = err * STEERING_Kp
            local derrivativeOutput = delta / dt * STEERING_Kd * steerControl

            local torque = proportionalOutput + derrivativeOutput
            steer.Torque = Vector3.new(0, math.sign(torque) * math.min(MAX_STEER_TORQUE, math.abs(torque)), 0) * mass

            local lean = math.clamp(err * 2, -1, 1) * (forcedAcceleration or 1)
            tailbone.CFrame = tailbone.CFrame:Lerp(
                seatingCFrame * CFrame.fromEulerAnglesYXZ(math.abs(math.sign(lean)) * math.rad(10), 0, lean * MAX_SEAT_LEAN_ANGLE),
                dt * 2
            )
        end

        -- Roll resistance
        do
            local roll = physicsPart.Orientation.Z
            alignRotation.MaxTorque = math.abs(roll) / 180 * MAX_ANGULAR_ALIGNMENT_TORQUE
            alignRotation.AngularVelocity = Vector3.new(0, 0, -roll) * mass
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
                emitter.Rate = driftParticleRate:UpdateOnStepped(
                    math.max(MIN_DRIFT_PARTICLE_RATE, MAX_DRIFT_PARTICLE_RATE * driftyness * MathUtil.map(speedyness, -1, 1, 0, 1)),
                    dt * 5
                )
            end

            camera.FieldOfView = BASE_FOV
                + driftFOVAddend:UpdateOnStepped(-MAX_DRIFT_FOV_MINUEND * driftyness, dt * 5)
                + speedFOVAddend:UpdateOnStepped(MAX_SPEED_FOV_ADDEND * math.max(0, speedyness), dt * 3)
        end
    end)

    local complete: RBXScriptConnection?
    complete = map.FinishLine.PrimaryPart.Touched:Connect(function(hit)
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

            forcedAcceleration = 1
            forcedSpeed = 0
        end
    end)

    -- Goo
    SledRaceUtil.unanchorSled(player)

    return function()
        driving:Disconnect()
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
