local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local BodyTypeConstants = {}
export type Item = {
    Height: Vector3,
    Price: number,
    Icon: string,
    LayoutOrder: number,
}

BodyTypeConstants.InventoryPath = "BodyTypes"
BodyTypeConstants.TabOrder = 6
BodyTypeConstants.TabIcon = Images.Icons.Face
BodyTypeConstants.SortOrder = Enum.SortOrder.LayoutOrder
BodyTypeConstants.MaxEquippables = 1
BodyTypeConstants.CanUnequip = false
BodyTypeConstants.Items = {
    ["Kid"] = {
        Height = Vector3.new(0, -0.4, 0),
        Price = 0,
        Icon = Images.BodyTypes.Kid,
        LayoutOrder = 1,
    } :: Item,
    ["Teen"] = {
        Height = Vector3.new(0, 0, 0),
        Price = 0,
        Icon = Images.BodyTypes.Teen,
        LayoutOrder = 2,
    } :: Item,
    ["Adult"] = {
        Height = Vector3.new(0, 0.4, 0),
        Price = 0,
        Icon = Images.BodyTypes.Adult,
        LayoutOrder = 3,
    } :: Item,
}

return BodyTypeConstants
