local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local BackpackConstant = {}
export type Item = {
    Price: number,
    Name: string,
    Icon: string,
}

local items: { [string]: Item } = {}
items["Angel_Wings"] = {
    Name = "Angel_Wings",
    Price = 0,
    Icon = Images.Backpacks["Angel_Wings"],
}
items["Brown_Backpack"] = {
    Name = "Brown_Backpack",
    Price = 0,
    Icon = Images.Backpacks["Brown_Backpack"],
}

BackpackConstant.AssetsPath = "Backpacks"
BackpackConstant.TabOrder = 6
BackpackConstant.TabIcon = Images.Icons.Bag
BackpackConstant.SortOrder = Enum.SortOrder.Name
BackpackConstant.MaxEquippables = 2
BackpackConstant.CanUnequip = true
BackpackConstant.Items = items

return BackpackConstant
