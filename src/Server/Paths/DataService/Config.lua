--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local houseDefaults = require(script.Parent.HouseDefault)
local defaultInventory = {}

DataConfig.DataKey = "DEV_2"
function DataConfig.getDefaults(player)
    return {
        Appearance = {
            BodyType = "Teen",
        },
        Inventory = defaultInventory,
        Igloo = {
            IglooPlot = "Default",
            IglooHouse = "Default",
            Placements = houseDefaults.getDefaults(),
            OwnedItems = {},
        },
        Gamepasses = {},
        Settings = {},
        RedeemedCodes = {},
    }
end

-- Load default character items into inventory
for _, module in ipairs(Paths.Shared.Constants.CharacterItems:GetChildren()) do
    local itemConstants = require(module)
    defaultInventory[itemConstants.Path] = {}
end

return DataConfig
