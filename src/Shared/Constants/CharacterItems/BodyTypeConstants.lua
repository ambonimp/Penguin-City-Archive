local BodyTypeConstants = {}
export type BodyType = {
    Height: Vector3,
    Price: number,
    Icon: string,
    LayoutOrder: number,
}

BodyTypeConstants.InventoryPath = "BodyTypes" -- Key in data stores
BodyTypeConstants.All = {
    ["Kid"] = {
        Height = Vector3.new(0, -0.4, 0),
        Price = 0,
        Icon = "",
        LayoutOrder = 1,
    },
    ["Teen"] = {
        Height = Vector3.new(0, 0, 0),
        Price = 0,
        Icon = "",
        LayoutOrder = 2,
    },
    ["Adult"] = {
        Height = Vector3.new(0, 0.4, 0),
        Price = 0,
        Icon = "",
        LayoutOrder = 3,
    },
}

return BodyTypeConstants
