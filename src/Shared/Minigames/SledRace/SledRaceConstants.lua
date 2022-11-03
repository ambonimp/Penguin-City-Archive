local SledRaceConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

local sessionConfig: MinigameConstants.SessionConfig = {
    -- Size
    MinParticipants = 2,
    MaxParticipants = 6,
    StrictlyEnforcePlayerCount = false,
    -- State lengths
    IntermissionLength = 30,
    CoreLength = 70,
    AwardShowLength = 20,
    CoreCountdown = true,
    -- Play types
    SinglePlayer = true,
    Multiplayer = true,
}

SledRaceConstants.SessionConfig = sessionConfig

SledRaceConstants.SteeringControllerGains = {
    Kp = 100,
    Kd = 15,
}

SledRaceConstants.SledName = "SledRaceSled"
SledRaceConstants.SledPhysicalProperties = PhysicalProperties.new(
    0.2, -- density
    0, -- friction
    0.1, -- elasticity
    500, -- frictionWeight
    100 -- elasticityWeight
)

SledRaceConstants.AngularAcceleration = math.rad(35)
SledRaceConstants.MaxSteerAngle = math.rad(60)

SledRaceConstants.MinSpeed = 30
SledRaceConstants.DefaultSpeed = 60
SledRaceConstants.MaxSpeed = 100
SledRaceConstants.Acceleration = 20
SledRaceConstants.MaxForce = 1000

SledRaceConstants.CollectableEffectDuration = 3
SledRaceConstants.BoostSpeedAdded = 25
SledRaceConstants.ObstacleSpeedMinuend = 15

SledRaceConstants.CollectableGrid = { Z = 6, X = 4 }
SledRaceConstants.Collectables = {
    Obstacle = { Tag = "SledRaceObstacle", Occupancy = 0.3 },
    Boost = { Tag = "SledRaceBoost", Occupancy = 0.15 },
    Coin = { Tag = "SledRaceCoin", Occupancy = 0.15 },
}

SledRaceConstants.CoinsPerCollectable = 12
SledRaceConstants.CoinValue = 4

return SledRaceConstants
