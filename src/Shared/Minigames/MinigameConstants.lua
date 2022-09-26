local MinigameConstants = {}

export type Session = {
    Minigame: string,
    Id: number,
}

export type PlayRequest = { Session: Session | nil, Error: string | nil }

MinigameConstants.Minigames = {
    Pizza = "Pizza",
}

return MinigameConstants
