--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local HouseDefault = require(script.Parent.HouseDefault)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

local defaultInventory = {}
--[[
DataConfig.ReconcileExceptions = {
    ["Placements"] = true,
}]]

DataConfig.DataKey = "DEV_4"
function DataConfig.getDefaults()
    return {
        Appearance = {
            BodyType = "Teen",
        },
        Inventory = defaultInventory,
        Igloo = HouseDefault.getIglooDefaults(),
        Products = {},
        ProductPurchaseReceiptKeys = {},
        Settings = {},
        RedeemedCodes = {},
        Stamps = {
            OwnedStamps = {},
            StampBook = StampUtil.getStampBookDataDefaults(),
        },
        Coins = 0,
    }
end

-- Load default character items into inventory
for _, module in ipairs(Paths.Shared.Constants.CharacterItems:GetChildren()) do
    local itemConstants = require(module)
    defaultInventory[itemConstants.Path] = {}
end

return DataConfig
