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
local function getDefaultHouse()
    return {
        Blueprint = "Default",

        Furniture = {
            Default = {
                ["1"] = {
                    Rotation = "0, 1.5707963705062866, 0",
                    Name = "SHELF_1",
                    Position = "28.2392578125, 4.583555221557617, -9.742435455322266",
                    Color = { [1] = "0.92549, 0.305882, 0", [2] = "0.560784, 0.298039, 0.164706", [3] = "1, 0, 0.74902" },
                    Normal = "0, 1, 0",
                },
                ["2"] = {
                    Rotation = "0, 10.210176467895508, 0",
                    Name = "NIGHTSTAND",
                    Position = "-12.19140625, 2.8154983520507812, -39.167236328125",
                    Color = {
                        [1] = "0.227451, 0.490196, 0.0823529",
                        [2] = "0.580392, 0.745098, 0.505882",
                        [3] = "0.960784, 0.803922, 0.188235",
                        [4] = "0.411765, 0.25098, 0.156863",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["3"] = {
                    Rotation = "0, 3.1415927410125732, 0",
                    Name = "Bed",
                    Position = "-1.431640625, 3.9864091873168945, -39.40618896484375",
                    Color = {
                        [1] = "0.670588, 0.247059, 0.45098",
                        [2] = "0.294118, 0.592157, 0.294118",
                        [3] = "0.854902, 0.52549, 0.478431",
                        [4] = "0.94902, 0.952941, 0.952941",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["4"] = {
                    Rotation = "0, 10.210176467895508, 0",
                    Name = "Stove",
                    Position = "-20.505859375, 2.7118606567382812, -28.30595588684082",
                    Color = {
                        [1] = "0.666667, 0.333333, 0",
                        [2] = "0.356863, 0.364706, 0.411765",
                        [3] = "0.105882, 0.164706, 0.207843",
                        [4] = "0.854902, 0.521569, 0.254902",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["5"] = {
                    Rotation = "0, 0, 0",
                    Name = "PLANT",
                    Position = "13.462890625, 5.0212249755859375, -17.701396942138672",
                    Color = { [1] = "0.807843, 0.380392, 0.211765", [2] = "0.760784, 0.403922, 0.223529", [3] = "1, 0, 0.74902" },
                    Normal = "0, 1, 0",
                },
                ["6"] = {
                    Rotation = "0, 0, 0",
                    Name = "Glass_Table_1",
                    Position = "14.9775390625, 2.3419675827026367, -19.139537811279297",
                    Color = { [1] = "0.686275, 0.866667, 1", [2] = "0.431373, 0.6, 0.792157", [3] = "1, 0, 0.74902" },
                    Normal = "0, 1, 0",
                },
                ["7"] = {
                    Rotation = "0, 1.5707963705062866, 0",
                    Name = "Couch_01",
                    Position = "27.61328125, 4.035096168518066, -18.931640625",
                    Color = {
                        [1] = "0.227451, 0.490196, 0.0823529",
                        [2] = "0.498039, 0.556863, 0.392157",
                        [3] = "0.780392, 0.67451, 0.470588",
                        [4] = "0.854902, 0.521569, 0.254902",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["8"] = {
                    Rotation = "0, 1.5707963705062866, 0",
                    Name = "Carpet",
                    Position = "2.7080078125, 0.5755043029785156, -12.793937683105469",
                    Color = {
                        [1] = "0.337255, 0.141176, 0.141176",
                        [2] = "0.482353, 0, 0.482353",
                        [3] = "0.854902, 0.52549, 0.478431",
                        [4] = "0.94902, 0.952941, 0.952941",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["9"] = {
                    Rotation = "0, 10.995573997497559, 0",
                    Name = "FRIDGE",
                    Position = "-21.931640625, 4.8831787109375, -17.705078125",
                    Color = {
                        [1] = "0.0705882, 0.933333, 0.831373",
                        [2] = "0.623529, 0.952941, 0.913725",
                        [3] = "0.0156863, 0.686275, 0.92549",
                        [4] = "0.458824, 0, 0",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["10"] = {
                    Rotation = "0, 4.71238899230957, 0",
                    Name = "Sink",
                    Position = "-22.4111328125, 3.142350196838379, -23.28085708618164",
                    Color = {
                        [1] = "0.227451, 0.490196, 0.0823529",
                        [2] = "0.498039, 0.556863, 0.392157",
                        [3] = "0.501961, 0.8, 0.301961",
                        [4] = "1, 1, 0",
                        [5] = "0.388235, 0.372549, 0.384314",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
                ["11"] = {
                    Rotation = "0, 0, 0",
                    Name = "TABLE_LAMP_02",
                    Position = "-12.251953125, 5.989845275878906, -39.22395324707031",
                    Color = {
                        [1] = "1, 0.419608, 0.419608",
                        [2] = "0.482353, 0, 0.482353",
                        [3] = "0.854902, 0.52549, 0.478431",
                        [4] = "0.94902, 0.952941, 0.952941",
                        [5] = "0.686275, 0.866667, 1",
                        [6] = "0.0352941, 0.537255, 0.811765",
                    },
                    Normal = "0, 1, 0",
                },
            },
        },
    }
end
local function getDefaultCharacterAppearance()
    return {
        BodyType = { ["1"] = "Teen" },
        FurColor = { ["1"] = "Black" },
        Hat = {},
        Backpack = {},
        Shirt = {},
        Pants = {},
        Shoes = {},
    }
end
--#endregion

function DataConfig.getDefaults(_player: Player): DataUtil.Store
    return {
        CharacterAppearance = getDefaultCharacterAppearance(),
        House = getDefaultHouse(),
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
        MinigameRecords = {},
        Tutorial = {},
        Session = {},
    } :: DataUtil.Store
end

return DataConfig
