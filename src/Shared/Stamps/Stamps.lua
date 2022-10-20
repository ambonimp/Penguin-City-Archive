export type StampType = "Location" | "Minigame" | "Igloo" | "Clothing" | "Pets" | "Events"
export type StampDifficulty = "Easy" | "Medium" | "Hard" | "Extreme" | "???"
export type StampTier = "Bronze" | "Silver" | "Gold"

export type Stamp = {
    Id: string,
    DisplayName: string,
    Description: string | { string },
    Type: StampType,
    Difficulty: StampDifficulty,
    ImageId: string,
    IsTiered: boolean?,
    Metadata: table?,
}

local stampTypes: { StampType } = { "Location", "Minigame", "Igloo", "Clothing", "Pets", "Events" }
local stampDifficulties: { StampDifficulty } = { "Easy", "Medium", "Hard", "Extreme", "???" }
local stampTiers: { StampTier } = { "Bronze", "Silver", "Gold" } --!! Must be in ascending order of importance

return {
    StampTypes = stampTypes,
    StampDifficulties = stampDifficulties,
    StampTiers = stampTiers,
}
