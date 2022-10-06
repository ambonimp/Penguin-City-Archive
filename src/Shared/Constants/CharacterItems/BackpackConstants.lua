local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local BackpackConstant = {}
export type Item = {
    Price: number,
    Icon: string,
}

BackpackConstant.InventoryPath = "Backpacks"
BackpackConstant.TabOrder = 5
BackpackConstant.TabIcon = Images.Icons.Bag
BackpackConstant.SortOrder = Enum.SortOrder.Name
BackpackConstant.MaxEquippables = 2
BackpackConstant.CanUnequip = true
BackpackConstant.Items = {
    ["Angel_Wings"] = {
        Price = 0,
        Icon = Images.Backpacks["Angel_Wings"],
    } :: Item,
    ["Brown_Backpack"] = {
        Price = 0,
        Icon = Images.Backpacks["Brown_Backpack"],
    } :: Item,
}

return BackpackConstant
