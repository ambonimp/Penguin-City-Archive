local MinigameConstants = {}

export type Session = {
    Minigame: string,
    Id: number,
}
export type PlayRequest = { Session: Session | nil, Error: string | nil }
export type SortedScores = { { Player: Player, Score: number } }
export type SessionConfig = {
    -- Size
    MinParticipants: number,
    MaxParticipants: number,
    StrictlyEnforcePlayerCount: boolean,
    -- State lengths
    IntermissionLength: number,
    CoreLength: number,
    AwardShowLength: number,
    CoreCountdown: boolean,
    -- Play types
    SinglePlayer: boolean,
    Multiplayer: boolean,
    --
    HigherScoreWins: boolean,
    ScoreFormatter: (number) -> (number | string)?,
}

MinigameConstants.Minigames = {
    Pizza = "Pizza",
    SledRace = "SledRace",
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
MinigameConstants.BlurSize = 8

return MinigameConstants
