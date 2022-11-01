local CharacterItems: {
    [string]: {
        InventoryPath: string,
        TabOrder: number,
        TabIcon: string,
        SortOrder: Enum.SortOrder,
        MaxEquippables: number,
        CanUnequip: boolean,
        Items: { [string]: Item },
    },
} =
    {}

type Item = {
    Name: string,
    Price: number,
    Icon: string,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

export type Appearance = { [string]: { string }? }

for _, module in pairs(script:GetChildren()) do
    CharacterItems[StringUtil.chopEnd(module.Name, "Constants")] = require(module)
end

return CharacterItems
