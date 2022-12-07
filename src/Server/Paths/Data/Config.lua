--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead

    !! Data Keys found in GameConstants
]]

local DataConfig = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local GameUtil = require(Paths.Shared.Utils.GameUtil)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

DataConfig.DataKey = GameUtil.getDataKey()
--#region Default constants
local defaultHouse = {
    Blueprint = "Default",
    -- TODO: Make this save items for every blueprint
    Furniture = {
        ["1"] = {
            Name = "Floor_Lamp_01",
            Color = { ".85, .42, .07", ".92, .72, .21" },
            Rotation = "0, 0, 0",
            Position = "6.019, 4.819, -15.510",
            Normal = "0, 1, 0",
            FromDefault = true,
        },
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
        House = defaultHouse,
        Products = {},
        ProductPurchaseReceiptKeys = {},
        Settings = {},
        RedeemedCodes = {},
        Stamps = {
            OwnedStamps = {},
            StampBook = StampUtil.getStampBookDataDefaults(),
        },
        Coins = 0,
        Rewards = {
            DailyReward = {
                BestStreak = 0,
                Entries = {},
                Unclaimed = {},
            },
        },
        Pets = {
            Eggs = {},
            Pets = {},
        },
    } :: DataUtil.Store
end

return DataConfig
