local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local PantsConstants = {}
export type Item = {
    Price: number,
    Icon: string,
}

PantsConstants.InventoryPath = "Pants"
PantsConstants.TabOrder = 2
PantsConstants.TabIcon = Images.Icons.Pants
PantsConstants.SortOrder = Enum.SortOrder.LayoutOrder
PantsConstants.MaxEquippables = 1
PantsConstants.CanUnequip = true
PantsConstants.Items = {
    ["Overalls"] = {
        Price = 0,
        Icon = Images.Pants["Overalls"],
    } :: Item,
    ["White_Pants"] = {
        Price = 0,
        Icon = Images.Pants["White_Pants"],
    } :: Item,
}

return PantsConstants
