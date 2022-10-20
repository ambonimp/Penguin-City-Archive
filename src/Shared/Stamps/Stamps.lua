export type StampType = "Location" | "Minigame" | "Igloo" | "Clothing" | "Pets" | "Events"
export type StampDifficulty = "Easy" | "Medium" | "Hard" | "Extreme" | "???"

export type Stamp = {
    Id: string,
    DisplayName: string,
    Description: string,
    Type: StampType,
    Difficulty: StampDifficulty,
    ImageId: string,
    Metadata: table?,
}

local stampTypes: { StampType } = { "Location", "Minigame", "Igloo", "Clothing", "Pets", "Events" }
local stampDifficulties: { StampDifficulty } = { "Easy", "Medium", "Hard", "Extreme", "???" }

return {
    StampTypes = stampTypes,
    StampDifficulties = stampDifficulties,
}
