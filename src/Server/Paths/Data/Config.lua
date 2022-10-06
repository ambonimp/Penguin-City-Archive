--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local houseDefaults = require(script.Parent.HouseDefault)
local defaultInventory = {}
--[[
DataConfig.ReconcileExceptions = {
    ["Placements"] = true,
}]]

DataConfig.DataKey = "DEV_3"
function DataConfig.getDefaults()
    return {
        Appearance = {
            BodyType = "Teen",
        },
        Inventory = defaultInventory,
        Igloo = {},
        Products = {},
        ProductPurchaseReceiptKeys = {},
        Settings = {},
        RedeemedCodes = {},
        Coins = 0,
    }
end

-- Load default character items into inventory
for _, module in ipairs(Paths.Shared.Constants.CharacterItems:GetChildren()) do
    local itemConstants = require(module)
    defaultInventory[itemConstants.Path] = {}
end

return DataConfig
