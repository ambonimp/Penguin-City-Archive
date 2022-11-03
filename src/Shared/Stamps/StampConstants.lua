local StampConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

export type StampBook = {
    CoverColors: { [string]: Color3 },
    CoverPattern: { [string]: string },
    TextColors: { [string]: Color3 },
    Seals: { [string]: {
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
    CoverColors = {
        Brown = Color3.fromRGB(161, 74, 53),
        Red = Color3.fromRGB(255, 0, 0),
    },
    CoverPattern = {
        Voldex = Images.StampBook.Patterns.Voldex,
        Circles = Images.StampBook.Patterns.Circles,
    },
    TextColors = {
        White = Color3.fromRGB(255, 255, 255),
        Blue = Color3.fromRGB(0, 0, 255),
    },
    Seals = {
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

local chapters: { Chapter } = {
    { StampType = "Location", DisplayName = "Locations", Icon = Images.Icons.Place, LayoutByMetadataKey = "Location" },
    { StampType = "Minigame", DisplayName = "Minigames", Icon = Images.Icons.Minigame, LayoutByMetadataKey = "Minigame" },
    { StampType = "Igloo", DisplayName = "Igloo", Icon = Images.Icons.Igloo },
    { StampType = "Clothing", DisplayName = "Clothing", Icon = Images.Icons.Shirt },
    { StampType = "Pets", DisplayName = "Pets", Icon = Images.Icons.Pets },
    { StampType = "Events", DisplayName = "Events", Icon = Images.Icons.Events, LayoutByMetadataKey = "Event" },
    --{ IsSearch = true, DisplayName = "Search", Icon = Images.Icons.Search },
}
StampConstants.Chapters = chapters

return StampConstants
