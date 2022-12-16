local BlueprintConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Object = {
    Name: string,
    Price: number,
    Icon: string,
    Rotation: CFrame | nil,
}

local objects: { [string]: Object } = {}
objects["Default"] = {
    Name = "Igloo",
    Price = 0,
    Icon = "",
}
objects["CircusTent"] = {
    Name = "Circus Tent",
    Price = 400,
    Icon = "",
}

objects["Dojo"] = {
    Name = "Dojo",
    Price = 1000,
    Icon = "",
}

BlueprintConstants.AssetsPath = "Exteriors"
BlueprintConstants.TabOrder = 5
BlueprintConstants.TabIcon = Images.Icons.Igloo
BlueprintConstants.Objects = objects

return BlueprintConstants
