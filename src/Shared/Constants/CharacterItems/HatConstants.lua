local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local HatConstants = {}

export type Hat = {
    Price: number,
    Icon: string,
} | true

HatConstants.InventoryPath = "Hats" -- Key in data stores
HatConstants.All = {
    ["Backwards_Cap"] = {
        Price = 0,
        Icon = Images.Hats["Backwards_Cap"],
    } :: Hat,
    ["Bird_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Bird_Hat"],
    } :: Hat,
    ["Boot_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Boot_Hat"],
    } :: Hat,
    ["Detective's_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Detective's_Hat"],
    } :: Hat,
    ["None"] = true :: Hat,
}

return HatConstants
