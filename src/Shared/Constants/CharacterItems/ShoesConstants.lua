local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local ShoesConstants = {}
export type Item = {
    Price: number,
    Icon: string,
}

ShoesConstants.InventoryPath = "Shoes"
ShoesConstants.TabOrder = 5
ShoesConstants.TabIcon = Images.Hats.Boot_Hat
ShoesConstants.SortOrder = Enum.SortOrder.LayoutOrder
ShoesConstants.MaxEquippables = 1
ShoesConstants.CanUnequip = true
ShoesConstants.Items = {
    ["Red_Sneakers"] = {
        Price = 0,
        Icon = Images.Shoes["Red_Sneakers"],
    } :: Item,
}

return ShoesConstants
