--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local GameUtil = require(Paths.Shared.Utils.GameUtil)

DataConfig.DataKey = GameUtil.getDataKey()

--#region Default constants
local defaultInventory = {}
local defaultIgloo = {
    IglooPlot = "Default",
    IglooHouse = "Default",
    Placements = {
        ["1"] = {
            Id = 1,
            Name = "Floor_Lamp_01",
            Color = "239,184,56",
            Rotation = "0,0,0",
            Position = "6.01904296875, 4.8195648193359375, -15.5107421875",
        },
    },
    OwnedItems = {
        ["Floor_Lamp_01"] = 3,
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

function DataConfig.getDefaults(_player: Player): DataUtil.Store
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
