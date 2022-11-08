local StampConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

export type StampBook = {
    CoverColor: { [string]: Color3 },
    CoverPattern: { [string]: string },
    TextColor: { [string]: Color3 },
    Seal: { [string]: {
        Color: Color3,
        Icon: string,
    } },
}

export type Chapter = {
    IsSearch: boolean?,
    StampType: Stamps.StampType?,
    DisplayName: string,
    Icon: string,
    LayoutByMetadataKey: string?,
}

-- Don't exceed ~800, so there is no overlap with the StampCount
local titleIconWidth: { [string]: number } = {
    [Images.StampBook.Titles.Icecream] = 800,
    [Images.StampBook.Titles.Pizza] = 600,
    [Images.StampBook.Titles.SledRace] = 600,
}
StampConstants.TitleIconWidth = titleIconWidth

local stampBook: StampBook = {
    CoverColor = {
        Brown = Color3.fromRGB(161, 74, 53),
        Red = Color3.fromRGB(255, 0, 0),
    },
    CoverPattern = {
        Voldex = Images.StampBook.Patterns.Voldex,
        Circles = Images.StampBook.Patterns.Circles,
    },
    TextColor = {
        White = Color3.fromRGB(255, 255, 255),
        Blue = Color3.fromRGB(0, 0, 255),
    },
    Seal = {
        Gold = {
            Color = Color3.fromRGB(238, 179, 18),
            Icon = "",
        },
        Igloo = {
            Color = Color3.fromRGB(240, 240, 240),
            Icon = Images.Icons.Igloo,
        },
    },
}
StampConstants.StampBook = stampBook

StampConstants.MaxCoverStamps = 6

local chapters: { Chapter } = {
    --{ StampType = "Location", DisplayName = "Locations", Icon = Images.Icons.Place, LayoutByMetadataKey = "Location" }, --!! 0 Stamps at time of development
    { StampType = "Minigame", DisplayName = "Minigames", Icon = Images.Icons.Minigame, LayoutByMetadataKey = "Minigame" },
    { StampType = "Igloo", DisplayName = "Igloo", Icon = Images.Icons.Igloo },
    { StampType = "Clothing", DisplayName = "Clothing", Icon = Images.Icons.Shirt },
    --{ StampType = "Pets", DisplayName = "Pets", Icon = Images.Icons.Pets }, --!! 0 Stamps at time of development
    { StampType = "Events", DisplayName = "Events", Icon = Images.Icons.Events, LayoutByMetadataKey = "Event" },
    --{ IsSearch = true, DisplayName = "Search", Icon = Images.Icons.Search }, --!! Search not implemented at time of development
}
StampConstants.Chapters = chapters

StampConstants.DifficultyColors = {
    Easy = Color3.fromRGB(109, 194, 53),
    Medium = Color3.fromRGB(231, 162, 57),
    Hard = Color3.fromRGB(175, 41, 41),
    Extreme = Color3.fromRGB(115, 64, 209),
    ["???"] = Color3.fromRGB(66, 243, 243),
}

StampConstants.TierColors = {
    Bronze = Color3.fromRGB(205, 127, 50),
    Silver = Color3.fromRGB(192, 192, 192),
    Gold = Color3.fromRGB(236, 210, 57),
}

return StampConstants
