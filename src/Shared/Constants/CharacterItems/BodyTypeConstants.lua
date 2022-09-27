local BodyTypeConstants = {}

BodyTypeConstants.Path = "BodyTypes" -- Key in data stores
BodyTypeConstants.All = {
    ["Kid"] = {
        Height = Vector3.new(0, -0.4, 0),
        Price = 0,
        LayoutOrder = 1,
    },
    ["Teen"] = {
        Height = Vector3.new(0, 0, 0),
        Price = 0,
        LayoutOrder = 2,
    },
    ["Adult"] = {
        Height = Vector3.new(0, 0.4, 0),
        Price = 0,
        LayoutOrder = 3,
    },
}

return BodyTypeConstants
