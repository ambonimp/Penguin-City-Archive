--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)

local defaultInventory = {}

DataConfig.DataKey = "DEV_2"
function DataConfig.getDefaults(player)
    return {
        CharacterAppearance = {
            BodyType = { "Teen" },
            FurColor = { "Black" },
            Hat = {},
            Backpack = {},
            Shirt = {},
            Pants = {},
            Shoes = {},
        },
        Inventory = defaultInventory,
        Igloo = {},
        Gamepasses = {},
        Settings = {},
        RedeemedCodes = {},
    }
end

-- Load default character items into inventory
for _, itemConstants in CharacterItems do
    defaultInventory[itemConstants.InventoryPath] = {}
end

return DataConfig
