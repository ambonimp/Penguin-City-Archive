--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local DataUtil = require(Paths.Shared.Utils.DataUtil)

--#region Default constants
local defaultInventory = {}
local defaultIgloo = {
    IglooPlot = "Default",
    IglooHouse = "Default",
    Placements = {
        ["1"] = { Id = 1, Position = { 0, 2.6, -16 }, Rotation = { 0, 0, 0 }, Color = { 124, 92, 70 }, Name = "Chair" },
    },
    OwnedItems = {
        ["Chair"] = 3,
        ["Couch"] = 3,
        ["Plant"] = 3,
        ["Table"] = 3,
        ["Table_Lamp"] = 3,
    },
}
local defaultCharacterAppearance = {
    BodyType = { ["1"] = "Teen" },
    FurColor = { ["1"] = "Black" },
    Hat = {},
    Backpack = {},
    Shirt = {},
    Pants = {},
    Shoes = {},
}
--#endregion

DataConfig.DataKey = "DEV_4"
function DataConfig.getDefaults(player: Player): DataUtil.Store
    return {
        CharacterAppearance = defaultCharacterAppearance,
        Inventory = defaultInventory,
        Igloo = defaultIgloo,
        Products = {},
        ProductPurchaseReceiptKeys = {},
        Settings = {},
        RedeemedCodes = {},
        Coins = 0,
    } :: DataUtil.Store
end

-- Load default character items into inventory
for _, itemConstants in pairs(CharacterItems) do
    defaultInventory[itemConstants.InventoryPath] = {}
end

return DataConfig
