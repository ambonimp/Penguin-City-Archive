local StampConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

StampConstants.TitleIconResolutions = {
    [Images.StampBook.Titles.Pizza] = Vector2.new(523, 90),
} :: { [string]: Vector2 }

StampConstants.StampBook = {
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

local pages: { {
    StampType: Stamps.StampType,
    DisplayName: string,
    Icon: string,
} } = {
    { StampType = "Location", DisplayName = "Locations", Icon = Images.Icons.Place },
    { StampType = "Minigame", DisplayName = "Minigames", Icon = Images.Icons.Minigame },
    { StampType = "Igloo", DisplayName = "Igloo", Icon = Images.Icons.Igloo },
    { StampType = "Clothing", DisplayName = "Clothing", Icon = Images.Icons.Shirt },
    { StampType = "Pets", DisplayName = "Pets", Icon = Images.Icons.Pets },
    { StampType = "Events", DisplayName = "Events", Icon = Images.Icons.Events },
}
StampConstants.Pages = pages

return StampConstants
