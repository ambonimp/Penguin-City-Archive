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
            Rotation = { [1] = 0, [2] = 0, [3] = 0 },
            Name = "TABLE",
            Position = { [1] = 6.01904296875, [2] = 1.7862319946289062, [3] = -15.5107421875 },
            Id = 1,
            Color = { [1] = 239, [2] = 184, [3] = 56 },
        },
        ["2"] = {
            Rotation = { [1] = 0, [2] = 180, [3] = 0 },
            Name = "BEAN_BAG",
            Position = { [1] = 0.48095703125, [2] = 3.5354652404785156, [3] = -41.56396484375 },
            Id = 2,
            Color = { [1] = 165, [2] = 55, [3] = 71 },
        },
        ["3"] = {
            Rotation = { [1] = 0, [2] = 225, [3] = 0 },
            Name = "BEAN_BAG",
            Position = { [1] = -6.3193359375, [2] = 3.5354652404785156, [3] = -37 },
            Id = 3,
            Color = { [1] = 74, [2] = 113, [3] = 244 },
        },
        ["4"] = {
            Rotation = { [1] = 0, [2] = 270, [3] = 0 },
            Name = "STOVE",
            Position = { [1] = -21.07470703125, [2] = 2.6618576049804688, [3] = -25.9716796875 },
            Id = 4,
            Color = { [1] = 170, [2] = 85, [3] = 0 },
        },
        ["5"] = {
            Rotation = { [1] = 0, [2] = 315, [3] = 0 },
            Name = "COUCH_03",
            Position = { [1] = -15.44091796875, [2] = 3.9659423828125, [3] = -4.13818359375 },
            Id = 5,
            Color = { [1] = 33, [2] = 84, [3] = 185 },
        },
        ["6"] = {
            Rotation = { [1] = 0, [2] = 45, [3] = 0 },
            Name = "CHAIR",
            Position = { [1] = 9.81005859375, [2] = 3.820568084716797, [3] = -10.00732421875 },
            Color = { [1] = 253, [2] = 192, [3] = 39 },
            Id = 6,
        },
        ["7"] = {
            Rotation = { [1] = 0, [2] = 180, [3] = 0 },
            Name = "FRIDGE",
            Position = { [1] = -13.88671875, [2] = 4.833179473876953, [3] = -33.96435546875 },
            Id = 7,
            Color = { [1] = 18, [2] = 238, [3] = 212 },
        },
        ["8"] = {
            Rotation = { [1] = 0, [2] = 180, [3] = 0 },
            Name = "BOOKSHELF",
            Position = { [1] = 6.77197265625, [2] = 5.694572448730469, [3] = -40.2001953125 },
            Id = 8,
            Color = { [1] = 16, [2] = 42, [3] = 220 },
        },
        ["9"] = {
            Rotation = { [1] = 0, [2] = 45, [3] = 0 },
            Name = "BED",
            Position = { [1] = 18.3447265625, [2] = 3.9364013671875, [3] = -31.5146484375 },
            Id = 9,
            Color = { [1] = 171, [2] = 63, [3] = 115 },
        },
        ["10"] = {
            Rotation = { [1] = 0, [2] = 0, [3] = 0 },
            Name = "TABLE_LAMP_01",
            Position = { [1] = 6.6845703125, [2] = 4.530189514160156, [3] = -17.69921875 },
            Id = 10,
            Color = { [1] = 196, [2] = 40, [3] = 28 },
        },
        ["11"] = {
            Rotation = { [1] = 0, [2] = 135, [3] = 0 },
            Name = "CHAIR",
            Position = { [1] = 9.66650390625, [2] = 3.820568084716797, [3] = -22.79150390625 },
            Id = 11,
            Color = { [1] = 253, [2] = 192, [3] = 39 },
        },
        ["12"] = {
            Rotation = { [1] = 0, [2] = 225, [3] = 0 },
            Name = "SINK",
            Position = { [1] = -19.5302734375, [2] = 3.09234619140625, [3] = -31.13330078125 },
            Id = 12,
            Color = { [1] = 58, [2] = 125, [3] = 21 },
        },
        ["13"] = {
            Rotation = { [1] = 0, [2] = 45, [3] = 0 },
            Name = "FIRE_PLACE",
            Position = { [1] = 20.7294921875, [2] = 3.9999961853027344, [3] = -0.99462890625 },
            Id = 13,
            Color = { [1] = 99, [2] = 95, [3] = 98 },
        },
        ["14"] = {
            Rotation = { [1] = 0, [2] = 270, [3] = 0 },
            Name = "FLOOR_LAMP_01",
            Position = { [1] = -22.2724609375, [2] = 4.8195648193359375, [3] = -21.82568359375 },
            Id = 14,
            Color = { [1] = 196, [2] = 40, [3] = 28 },
        },
        ["15"] = {
            Rotation = { [1] = 0, [2] = 270, [3] = 0 },
            Name = "COUCH_01",
            Position = { [1] = -20.81787109375, [2] = 3.985088348388672, [3] = -16.6630859375 },
            Id = 15,
            Color = { [1] = 58, [2] = 125, [3] = 21. },
        },
        ["16"] = {
            Rotation = { [1] = 0, [2] = 90, [3] = 0 },
            Name = "COUCH_02",
            Position = { [1] = 24.3369140625, [2] = 3.985218048095703, [3] = -13.6611328125 },
            Id = 16,
            Color = { [1] = 123, [2] = 0, [3] = 123 },
        },
        ["17"] = {
            Rotation = { [1] = 0, [2] = 225, [3] = 0 },
            Name = "TABLE",
            Position = { [1] = -5.400390625, [2] = 1.7862319946289062, [3] = -23.38330078125 },
            Id = 17,
            Color = { [1] = 74, [2] = 113, [3] = 244 },
        },
        ["18"] = {
            Rotation = { [1] = 0, [2] = 315, [3] = 0 },
            Name = "CAMPING_CHAIR",
            Position = { [1] = 10.6953125, [2] = 3.6279563903808594, [3] = -36.751953125 },
            Id = 18,
            Color = { [1] = 226, [2] = 155, [3] = 64 },
        },
        ["19"] = {
            Rotation = { [1] = 0, [2] = 0, [3] = 0 },
            Name = "TABLE_LAMP_01",
            Position = { [1] = -6.4267578125, [2] = 4.530185699462891, [3] = -22.68994140625 },
            Id = 19,
            Color = { [1] = 197, [2] = 116, [3] = 245 },
        },
        ["20"] = {
            Rotation = { [1] = 0, [2] = 0, [3] = 0 },
            Name = "CHAIR",
            Position = { [1] = -5.61279296875, [2] = 3.820568084716797, [3] = -16.2294921875 },
            Id = 20,
            Color = { [1] = 74, [2] = 113, [3] = 244 },
        },
        ["21"] = {
            Rotation = { [1] = 0, [2] = 90, [3] = 0 },
            Name = "FLOOR_LAMP_02",
            Position = { [1] = 26.1953125, [2] = 4.733074188232422, [3] = -22.892578125 },
            Id = 21,
            Color = { [1] = 52, [2] = 142, [3] = 64 },
        },
    },
    OwnedItems = {
        ["FLOOR_LAMP_01"] = 3,
        ["FLOOR_LAMP_02"] = 3,
        ["BEAN_BAG"] = 3,
        ["BED"] = 3,
        ["BOOKSHELF"] = 3,
        ["CAMPING_CHAIR"] = 3,
        ["CHAIR"] = 3,
        ["COUCH_01"] = 3,
        ["COUCH_02"] = 3,
        ["COUCH_03"] = 3,
        ["FRIDGE"] = 3,
        ["FIRE_PLACE"] = 3,
        ["SINK"] = 3,
        ["STOVE"] = 3,
        ["TABLE"] = 3,
        ["TABLE_LAMP_01"] = 3,
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
