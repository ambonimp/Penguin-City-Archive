local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local PantsConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Overalls"] = {
    Name = "Overalls",
    Price = 0,
    Icon = Images.Pants["Overalls"],
    ForSale = false,
}
items["White_Pants"] = {
    Name = "White_Pants",
    Price = 0,
    Icon = Images.Pants["White_Pants"],
    ForSale = true,
}

PantsConstants.AssetsPath = "Pants"
PantsConstants.TabOrder = 2
PantsConstants.TabIcon = Images.Icons.Pants
PantsConstants.SortOrder = Enum.SortOrder.LayoutOrder
PantsConstants.MaxEquippables = 1
PantsConstants.CanUnequip = true
PantsConstants.Items = items

return PantsConstants
