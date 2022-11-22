local BlueprintConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Object = {
    Name: string,
    Price: number,
    Icon: string,
}

local objects: { [string]: Object } = {}
objects["Default"] = {
    Name = "Default",
    Price = 0,
    Icon = "",
}
objects["House"] = {
    Name = "House",
    Price = 0,
    Icon = "",
}

BlueprintConstants.AssetsPath = "Exteriors"
BlueprintConstants.TabOrder = 5
BlueprintConstants.TabIcon = Images.Icons.Igloo
BlueprintConstants.Objects = objects

return BlueprintConstants
