local RewardsConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type DailyStreakReward = {
    Coins: number | nil,
    Gift: {
        Name: string,
        Type: GiftType,
        Data: GiftData,
    } | nil,
    Icon: string | nil,
    Color: Color3,
}

export type GiftType = "Coins" | "Clothing" | "House" | "Outfit"
export type GiftData = {
    Coins: number?,
    ProductType: string?,
    ProductId: string?,
}
export type Gift = {
    Type: GiftType,
    Weight: number,
    Data: {
        Coins: number?,
        Clothing: {
            [string]: { string }, -- categoryName: itemName
        }?,
        House: {
            [string]: { string }, -- categoryName: objectName
        }?,
        Outfit: { string }?,
    },
}

local dailyStreakRewards: { DailyStreakReward } = {
    { Coins = 25, Icon = Images.Coins.Bundle1, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 100, Icon = Images.Coins.Bundle2, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 250, Icon = Images.Coins.Bundle3, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 500, Icon = Images.Coins.Bundle4, Color = Color3.fromRGB(172, 89, 193) },
    { Gift = {}, Icon = Images.Icons.Gift, Color = Color3.fromRGB(222, 125, 37) },
}

RewardsConstants.DailyStreak = {
    StoreMaxDays = 5,
    RenewAfterHours = 24,
    ExpireAfterHours = 28,
    Rewards = dailyStreakRewards,
}

local giftTypes: { GiftType } = { "Coins", "Clothing", "House", "Outfit" }
RewardsConstants.GiftTypes = giftTypes

local giftNames: { [string]: string } = {
    ["Small Gift"] = "Small Gift",
    ["Medium Gift"] = "Medium Gift",
    ["Mystery Coins"] = "Mystery Coins",
    ["Large Gift"] = "Large Gift",
    ["Rare Gift"] = "Rare Gift",
    ["Extraordinary Gift"] = "Extraordinary Gift",
}
RewardsConstants.GiftNames = giftNames

local gifts: { [string]: { Gift } } = {
    --#region Small Gift
    ["Small Gift"] = {
        {
            Type = "Clothing",
            Weight = 40,
            Data = {
                Clothing = {
                    Backpack = {
                        "Angel_Wings",
                        "Brown_Backpack",
                    },
                },
            },
        },
        {
            Type = "House",
            Weight = 40,
            Data = {
                House = {
                    Furniture = {
                        "Camping_Chair",
                        "Chair",
                    },
                },
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 150,
            },
        },
    },
    --#endregion
    --#region Medium Gift
    ["Medium Gift"] = {
        {
            Type = "Clothing",
            Weight = 40,
            Data = {
                Clothing = {
                    Pants = {
                        "Overalls",
                    },
                    Shirt = {
                        "Flannel_Shirt",
                    },
                },
            },
        },
        {
            Type = "House",
            Weight = 40,
            Data = {
                House = {
                    Furniture = {
                        "Couch_01",
                        "Couch_02",
                        "Couch_03",
                    },
                },
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 400,
            },
        },
    },
    --#endregion
    --#region Mystery Coins
    ["Mystery Coins"] = {
        {
            Type = "Coins",
            Weight = 30,
            Data = {
                Coins = 500,
            },
        },
        {
            Type = "Coins",
            Weight = 30,
            Data = {
                Coins = 550,
            },
        },
        {
            Type = "Coins",
            Weight = 15,
            Data = {
                Coins = 650,
            },
        },
        {
            Type = "Coins",
            Weight = 15,
            Data = {
                Coins = 1000,
            },
        },
        {
            Type = "Coins",
            Weight = 10,
            Data = {
                Coins = 2000,
            },
        },
    },
    --#endregion
    --#region Large Gift
    ["Large Gift"] = {
        {
            Type = "Outfit",
            Weight = 40,
            Data = {
                Outfit = {
                    "Farmer",
                },
            },
        },
        {
            Type = "House",
            Weight = 40,
            Data = {
                House = {
                    Furniture = {
                        "Fridge",
                        "Sink",
                        "Stove",
                    },
                },
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 1000,
            },
        },
    },
    --#endregion
    --#region Rare Gift
    ["Rare Gift"] = {
        {
            Type = "Outfit",
            Weight = 40,
            Data = {
                Outfit = {
                    "Farmer",
                },
            },
        },
        {
            Type = "House",
            Weight = 40,
            Data = {
                House = {
                    Furniture = {
                        "Table",
                        "Table_Lamp_01",
                    },
                },
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 1500,
            },
        },
    },
    --#endregion
    --#region Extraordinary Gift
    ["Extraordinary Gift"] = {
        {
            Type = "Outfit",
            Weight = 40,
            Data = {
                Outfit = {
                    "Farmer",
                },
            },
        },
        {
            Type = "House",
            Weight = 40,
            Data = {
                House = {
                    Furniture = {
                        "Bean_Bag",
                        "Bed",
                    },
                },
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 2000,
            },
        },
    },
    --#endregion
}
RewardsConstants.Gifts = gifts

RewardsConstants.Paycheck = {
    EverySeconds = 10 * 60,
    Coins = {
        Base = 100,
        Add = 25,
        Max = 200,
    },
}

return RewardsConstants
