local IceCreamExtravaganzaConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

local sessionConfig: MinigameConstants.SessionConfig = {
    -- Size
    MinParticipants = 1,
    MaxParticipants = 6,
    StrictlyEnforcePlayerCount = true,
    -- State lengths
    IntermissionLength = 15,
    CoreLength = 45,
    AwardShowLength = 5,
    CoreCountdown = true,
    -- Play types
    SinglePlayer = true,
    Multiplayer = true,
    Loop = true,
    --
    HigherScoreWins = true,
    Reward = function(placement): number
        if placement == 1 then
            return 35
        elseif placement == 2 then
            return 25
        elseif placement == 3 then
            return 15
        else
            return 10
        end
    end,
}

IceCreamExtravaganzaConstants.SessionConfig = sessionConfig

IceCreamExtravaganzaConstants.WalkSpeed = 50
IceCreamExtravaganzaConstants.DropVelocity = 12
IceCreamExtravaganzaConstants.CollectableDropRate = 0.4
IceCreamExtravaganzaConstants.InvicibilityLength = 5

IceCreamExtravaganzaConstants.CollectableContainerName = "Collectables"
IceCreamExtravaganzaConstants.CollectableDropProbability = {
    { Weight = 5, Value = "Invicible" },
    { Weight = 10, Value = "Double" },
    { Weight = 35, Value = "Obstacle" },
    { Weight = 50, Value = "Regular" },
}

IceCreamExtravaganzaConstants.FloorPhysicalProperties = PhysicalProperties.new(
    1, -- density
    0, -- friction
    0.1, -- elasticity
    200, -- frictionWeight
    200 -- elasticityWeight
)

return IceCreamExtravaganzaConstants
