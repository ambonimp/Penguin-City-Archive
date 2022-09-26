local MinigameConstants = {}

export type Session = {
    Minigame: string,
    Id: number,
}

export type PlayRequest = { Session: Session | nil, Error: string | nil }

MinigameConstants.Minigames = {
    Pizza = "Pizza",
}

MinigameConstants.DoDebug = true

return MinigameConstants
