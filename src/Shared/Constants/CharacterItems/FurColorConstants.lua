local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurColorConstants = {}

export type FurColor = {
    Price: number,
    Icon: string,
    Color: Color3,
}

FurColorConstants.InventoryPath = "FurColors" -- Key in data stores
FurColorConstants.All = {
    ["Matte"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(27, 42, 53),
    } :: FurColor,
    ["Red"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 0, 0),
    } :: FurColor,
    ["Blue"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 0, 255),
    } :: FurColor,
    ["Green"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 255, 0),
    } :: FurColor,
    ["Yellow"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 255, 0),
    } :: FurColor,
}

return FurColorConstants
