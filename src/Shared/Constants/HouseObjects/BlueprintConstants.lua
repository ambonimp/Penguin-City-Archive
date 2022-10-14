local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local BlueprintConstants = {}

export type Object = {
    Name: string,
    Price: number,
    Icon: string,
}

BlueprintConstants.TabOrder = 5
BlueprintConstants.TabIcon = Images.Icons.Igloo

BlueprintConstants.Objects = {
    ["Default"] = {
        Name = "Default",
        Price = 0,
        Icon = "",
    } :: Object,
    ["House"] = {
        Name = "House",
        Price = 0,
        Icon = "",
    },
}

return BlueprintConstants
