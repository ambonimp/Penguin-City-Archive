local SledRaceConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

local sessionConfig: MinigameConstants.SessionConfig = {
    -- Size
    MinParticipants = 1,
    MaxParticipants = 4,
    StrictlyEnforcePlayerCount = false,
    -- State lengths
    IntermissionLength = 15,
    CoreLength = 70,
    AwardShowLength = 5,
    CoreCountdown = true,
    -- Play types
    SinglePlayer = true,
    Multiplayer = true,
    --
    HigherScoreWins = false,
    ScoreFormatter = function(score: number): string
        return (score / 10 ^ 2) .. "s"
    end,
    Reward = function(placement, _, isMultiplayer): number
        if isMultiplayer then
            if placement == 1 then
                return 35
            elseif placement == 2 then
                return 25
            elseif placement == 3 then
                return 15
            end
        end

        return 10
    end,
}

SledRaceConstants.SessionConfig = sessionConfig

SledRaceConstants.SledName = "SledRaceSled"
SledRaceConstants.SledPhysicalProperties = PhysicalProperties.new(
    100, -- density
    0, -- friction
    0, -- elasticity
    200, -- frictionWeight
    200 -- elasticityWeight
)

SledRaceConstants.SteeringControllerGains = {
    Kp = math.rad(80),
    Kd = math.rad(10),
}

SledRaceConstants.AngularAcceleration = math.rad(35)
SledRaceConstants.MaxSteerAngle = math.rad(60)

SledRaceConstants.MinSpeed = 60
SledRaceConstants.DefaultSpeed = 80
SledRaceConstants.MaxSpeed = 120
SledRaceConstants.Acceleration = 20
SledRaceConstants.MaxForce = 1000

SledRaceConstants.CollectableEffectDuration = 3
SledRaceConstants.BoostSpeedAdded = 25
SledRaceConstants.ObstacleSpeedMinuend = 10

SledRaceConstants.CollectableGrid = { Z = 14, X = 4 }
SledRaceConstants.Collectables = {
    Obstacle = { Tag = "SledRaceObstacle", Occupancy = 0.3 },
    Boost = { Tag = "SledRaceBoost", Occupancy = 0.15 },
    Coin = { Tag = "SledRaceCoin", Occupancy = 0.15 },
}

SledRaceConstants.CoinsPerCollectable = 12
SledRaceConstants.CoinValue = 4

return SledRaceConstants
