local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local CharacterItemConstants = ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants
local ShirtConstants = require(CharacterItemConstants.ShirtConstants)
local PantsConstants = require(CharacterItemConstants.PantsConstants)

local OutfitConstants = {}

export type OutfitConstants = {
    Shirt: { string }?,
    Hat: { string }?,
    Pants: { string }?,
    Shoes: { string }?,
}
export type Item = {
    Price: number,
    Icon: string,
    Name: string,
    Items: OutfitConstants,
}

local items: { [string]: Item } = {}
items["Farmer"] = {
    Name = "Farmer",
    Price = 0,
    Icon = Images.Outfits["Farmer"],
    Items = {
        Shirt = { ShirtConstants.Items["Flannel_Shirt"].Name },
        Pants = { PantsConstants.Items["Overalls"].Name },
    },
}

OutfitConstants.TabOrder = 4
OutfitConstants.TabIcon = Images.Icons.Outfit
OutfitConstants.SortOrder = Enum.SortOrder.LayoutOrder
OutfitConstants.MaxEquippables = 0
OutfitConstants.CanUnequip = false
OutfitConstants.Items = items

return OutfitConstants
