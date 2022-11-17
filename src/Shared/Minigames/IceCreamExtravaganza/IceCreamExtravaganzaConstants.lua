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
    --
    HigherScoreWins = true,
    ScoreFormatter = function(score: number): string
        return (score / 10 ^ 2) .. "s"
    end,
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

IceCreamExtravaganzaConstants.WalkSpeed = 60
IceCreamExtravaganzaConstants.DropVelocity = 12
IceCreamExtravaganzaConstants.CollectableDropRate = 0.4
IceCreamExtravaganzaConstants.InvicibilityLength = 5

IceCreamExtravaganzaConstants.CollectableDropProbability = {
    Invicible = 5,
    Double = 10,
    Obstacle = 28,
    Regular = 57,
}

IceCreamExtravaganzaConstants.SessionConfig = sessionConfig

return IceCreamExtravaganzaConstants
