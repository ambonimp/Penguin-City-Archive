local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local ShoesConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
}

local items: { [string]: Item } = {}
items["Red_Sneakers"] = {
    Name = "Red_Sneakers",
    Price = 0,
    Icon = Images.Shoes["Red_Sneakers"],
}

ShoesConstants.AssetsPath = "Shoes"
ShoesConstants.TabOrder = 3
ShoesConstants.TabIcon = Images.Icons.Shoe
ShoesConstants.SortOrder = Enum.SortOrder.LayoutOrder
ShoesConstants.MaxEquippables = 1
ShoesConstants.CanUnequip = true
ShoesConstants.Items = items

return ShoesConstants
