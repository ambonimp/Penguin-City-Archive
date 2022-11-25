local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local BodyTypeConstants = {}
export type Item = {
    Name: string,
    Height: Vector3,
    Price: number,
    Icon: string,
    Height: Vector3,
    LayoutOrder: number,
}

local items: { [string]: Item } = {}
items["Kid"] = {
    Name = "Kid",
    Height = Vector3.new(0, -0.4, 0),
    Price = 0,
    Icon = Images.BodyTypes.Kid,
    LayoutOrder = 1,
}
items["Teen"] = {
    Name = "Teen",
    Height = Vector3.new(0, 0, 0),
    Price = 0,
    Icon = Images.BodyTypes.Teen,
    LayoutOrder = 2,
}
items["Adult"] = {
    Name = "Adult",
    Height = Vector3.new(0, 0.4, 0),
    Price = 0,
    Icon = Images.BodyTypes.Adult,
    LayoutOrder = 3,
}

BodyTypeConstants.TabOrder = 7
BodyTypeConstants.TabIcon = Images.Icons.Face
BodyTypeConstants.SortOrder = Enum.SortOrder.LayoutOrder
BodyTypeConstants.MaxEquippables = 1
BodyTypeConstants.CanUnequip = false
BodyTypeConstants.Items = items

return BodyTypeConstants
