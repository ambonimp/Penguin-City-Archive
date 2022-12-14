local HouseObjects: {
    [string]: {
        AssetsPath: string,
        TabOrder: number,
        TabIcon: string,
        Objects: { [string]: Object },
    },
} =
    {}

type Object = {
    Name: string,
    Type: string, -- Furniture
    Price: number,
    Icon: string,
    Interactable: boolean?, -- Furniture
    Rotation: CFrame | nil,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

for _, module in script:GetChildren() do
    HouseObjects[StringUtil.chopEnd(module.Name, "Constants")] = require(module)
end

return HouseObjects
