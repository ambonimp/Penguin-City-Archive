local MinigameConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameUtil = require(ReplicatedStorage.Shared.Utils.GameUtil)

export type Session = {
    Minigame: string,
    Id: number,
}
export type PlayRequest = { Session: Session | nil, Error: string | nil }
export type SortedScores = { { Player: Player, Score: number } }
export type SessionConfig = {
    -- Size
    MinParticipants: number?,
    MaxParticipants: number?,
    StrictlyEnforcePlayerCount: boolean?,
    -- State lengths
    IntermissionLength: number?,
    CoreLength: number?,
    AwardShowLength: number?,
    CoreCountdown: boolean,
    -- Play types
    SinglePlayer: boolean,
    Multiplayer: boolean,
    --
    HigherScoreWins: boolean?,
    ScoreFormatter: ((number) -> (number | string))?,
    Reward: (placement: number, score: number) -> (number)?,
}

MinigameConstants.MaximumSufficientlyFilledQueueLength = if GameUtil.isDevGame() or GameUtil.isBranchGame() then 1 else 15

MinigameConstants.Minigames = {
    PizzaFiasco = "PizzaFiasco",
    SledRace = "SledRace",
    IceCreamExtravaganza = "IceCreamExtravaganza",
}

MinigameConstants.States = {
    Nothing = "Nothing",
    Intermission = "Intermission",
    Core = "Core",
    CoreCountdown = "CoreCountdown",
    WaitingForPlayers = "WaitingForPlayers",
    AwardShow = "AwardShow",
}

MinigameConstants.DoDebug = false -- Set to false to stop getting minigame debug messages
MinigameConstants.CoreCountdownLength = 4
MinigameConstants.BlurSize = 8

return MinigameConstants
