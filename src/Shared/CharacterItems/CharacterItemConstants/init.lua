local CharacterItemConstants: {
    [string]: Category,
} = {}

export type Category = {
    AssetsPath: string,
    TabOrder: number,
    TabIcon: string,
    SortOrder: Enum.SortOrder,
    MaxEquippables: number,
    CanUnequip: boolean,
    Items: { [string]: Item },
}

type Item = {
    Name: string,
    Price: number,
    Icon: string,
    Color: Color3?, -- FurColor
    LayoutOrder: number?, -- BodyType
    Height: Vector3?, -- BodyType
    Items: table?, -- Outfits
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

export type Appearance = { [string]: { string }? }

for _, module in pairs(script:GetChildren()) do
    CharacterItemConstants[StringUtil.chopEnd(module.Name, "Constants")] = require(module)
end

return CharacterItemConstants
