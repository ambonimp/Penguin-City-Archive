local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local ShirtConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
}

local items: { [string]: Item } = {}
items["Purple_Shirt"] = {
    Name = "Purple_Shirt",
    Price = 0,
    Icon = Images.Shirts["Purple_Shirt"],
}
items["Flannel_Shirt"] = {
    Name = "Flannel_Shirt",
    Price = 0,
    Icon = Images.Shirts["Flannel_Shirt"],
}

ShirtConstants.InventoryPath = "Shirts"
ShirtConstants.TabOrder = 1
ShirtConstants.TabIcon = Images.Icons.Shirt
ShirtConstants.SortOrder = Enum.SortOrder.LayoutOrder
ShirtConstants.MaxEquippables = 1
ShirtConstants.CanUnequip = true
ShirtConstants.Items = items

return ShirtConstants
