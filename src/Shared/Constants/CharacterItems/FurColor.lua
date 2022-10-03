local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurColorConstants = {}

FurColorConstants.Path = "BodyTypes" -- Key in data stores
FurColorConstants.All = {
    ["Matte"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(27, 42, 53),
        LayoutOrder = 1,
    },
    ["Red"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 0, 0),
        LayoutOrder = 2,
    },
    ["Blue"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 0, 255),
        LayoutOrder = 3,
    },
    ["Green"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 255, 0),
        LayoutOrder = 4,
    },
    ["Yellow"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 255, 0),
        LayoutOrder = 5,
    },
}

return FurColorConstants
