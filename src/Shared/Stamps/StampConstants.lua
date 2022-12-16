local StampConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

export type StampBook = {
    CoverColor: { [string]: { Primary: Color3, Secondary: Color3 } },
    CoverPattern: { [string]: string },
    TextColor: { [string]: Color3 },
    Seal: { [string]: {
        Color: Color3,
        IconColor: Color3?,
        Icon: string?,
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
    [Images.StampBook.Titles.Pizza] = 600,
    [Images.StampBook.Titles.Icecream] = 800,
    [Images.StampBook.Titles.SledRace] = 600,
}
StampConstants.TitleIconWidth = titleIconWidth

local stampBook: StampBook = {
    CoverColor = {
        Brown = {
            Primary = Color3.fromRGB(161, 74, 53),
            Secondary = Color3.fromRGB(94, 26, 9),
        },
        Charcoal = {
            Primary = Color3.fromRGB(79, 79, 79),
            Secondary = Color3.fromRGB(27, 27, 27),
        },
        Pink = {
            Primary = Color3.fromRGB(226, 0, 234),
            Secondary = Color3.fromRGB(140, 0, 147),
        },
        Purple = {
            Primary = Color3.fromRGB(141, 0, 241),
            Secondary = Color3.fromRGB(84, 0, 144),
        },
        White = {
            Primary = Color3.fromRGB(230, 230, 230),
            Secondary = Color3.fromRGB(255, 255, 255),
        },
        Blue = {
            Primary = Color3.fromRGB(0, 142, 230),
            Secondary = Color3.fromRGB(0, 97, 153),
        },
        Green = {
            Primary = Color3.fromRGB(22, 166, 0),
            Secondary = Color3.fromRGB(29, 220, 0),
        },
        Black = {
            Primary = Color3.fromRGB(35, 35, 35),
            Secondary = Color3.fromRGB(0, 0, 0),
        },
        Gold = {
            Primary = Color3.fromRGB(255, 217, 0),
            Secondary = Color3.fromRGB(167, 142, 0),
        },
    },
    CoverPattern = {
        Voldex = Images.StampBook.Patterns.Voldex,
        Circles = Images.StampBook.Patterns.Circles,
    },
    TextColor = {
        Brown = Color3.fromRGB(161, 74, 53),
        Charcoal = Color3.fromRGB(79, 79, 79),
        Pink = Color3.fromRGB(226, 0, 234),
        Purple = Color3.fromRGB(141, 0, 241),
        White = Color3.fromRGB(230, 230, 230),
        Blue = Color3.fromRGB(0, 142, 230),
        Green = Color3.fromRGB(22, 166, 0),
        Black = Color3.fromRGB(35, 35, 35),
        Gold = Color3.fromRGB(255, 217, 0),
    },
    Seal = {
        Gold = {
            Color = Color3.fromRGB(238, 179, 18),
        },
        Charcoal = {
            Color = Color3.fromRGB(79, 79, 79),
        },
        Purple = {
            Color = Color3.fromRGB(141, 0, 241),
        },
        Blue = {
            Color = Color3.fromRGB(0, 142, 230),
        },
        Igloo = {
            Color = Color3.fromRGB(240, 240, 240),
            IconColor = Color3.fromRGB(30, 30, 30),
            Icon = Images.Icons.Igloo,
        },
        Pencil = {
            Color = Color3.fromRGB(110, 110, 110),
            IconColor = Color3.fromRGB(255, 255, 255),
            Icon = Images.ButtonIcons.Pencil,
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
