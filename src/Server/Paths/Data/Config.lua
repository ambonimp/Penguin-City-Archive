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
        Appearance = {
            BodyType = "Teen",
            FurColor = "Matte",
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
