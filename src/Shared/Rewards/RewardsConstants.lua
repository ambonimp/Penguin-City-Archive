local RewardsConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type DailyRewardReward = {
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
        PetEgg: string?,
    },
}

local dailyRewardRewards: { DailyRewardReward } = {
    { Coins = 25, Icon = Images.Coins.Bundle1, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 100, Icon = Images.Coins.Bundle2, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 250, Icon = Images.Coins.Bundle3, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 500, Icon = Images.Coins.Bundle4, Color = Color3.fromRGB(172, 89, 193) },
    { Gift = {}, Icon = Images.Icons.Gift, Color = Color3.fromRGB(222, 125, 37) },
}

RewardsConstants.DailyReward = {
    StoreMaxDays = 5,
    RenewAfterHours = 24,
    ExpireAfterHours = 28,
    Rewards = dailyRewardRewards,
}

local giftTypes: { GiftType } = { "Coins", "Clothing", "House", "Outfit", "PetEgg" }
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
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 150,
            },
        },
        {
            Type = "PetEgg",
            Weight = 5,
            Data = {
                PetEgg = "Common",
            },
        },
        {
            Type = "Clothing",
            Weight = 30,
            Data = {
                Clothing = {
                    Backpack = {
                        "Brown_Backpack",
                    },
                    Hat = {
                        "Pizza_Chef_Hat",
                        "Ice_Cream_Hat",
                        "Bamboo_Straw_Hat",
                        "Adventurer_Hat",
                    },
                    Pants = {
                        "Bright_Green_Pants",
                    },
                    Shirt = {
                        "Pink_Starry_Shirt",
                        "Green_Spotted_Shirt",
                    },
                    Shoes = {
                        "Blue_Slippers",
                    },
                },
            },
        },
        {
            Type = "House",
            Weight = 60,
            Data = {
                House = {
                    Furniture = {
                        "Gaming_Chair",
                        "Bean_Bag",
                        "Couch_02",
                    },
                },
            },
        },
    },
    --#endregion
    --#region Medium Gift
    ["Medium Gift"] = {
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 200,
            },
        },
        {
            Type = "PetEgg",
            Weight = 5,
            Data = {
                PetEgg = "Common",
            },
        },
        {
            Type = "Clothing",
            Weight = 30,
            Data = {
                Clothing = {

                    Hat = {

                        "Feather_Hat",
                        "Flower_Pot",
                        "Hair_Headband",
                        "Pink_Bunny_Ears",
                        "Pot",
                    },
                    Pants = {

                        "Student_Pants",
                        "Purple_Pants",
                        "Pink_Pants",
                    },
                    Shirt = {

                        "Green_Starry_Shirt",
                        "Red_Starry_Shirt",
                        "Purple_Shirt",
                        "Orange_Gradient_Shirt",
                    },
                    Shoes = {

                        "White_Green_Sneakers",
                        "Tailor_Slippers",
                    },
                },
            },
        },
        {
            Type = "House",
            Weight = 60,
            Data = {
                House = {
                    Furniture = {
                        "Entertainment_Center",
                        "COMPUTER_TABLE",
                        "Couch_03",
                    },
                },
            },
        },
    },
    --#endregion
    --#region Mystery Coins
    ["Mystery Coins"] = {
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 150,
            },
        },
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 175,
            },
        },
        {
            Type = "Coins",
            Weight = 15,
            Data = {
                Coins = 200,
            },
        },
        {
            Type = "Coins",
            Weight = 15,
            Data = {
                Coins = 250,
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 300,
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 400,
            },
        },
        {
            Type = "Coins",
            Weight = 20,
            Data = {
                Coins = 500,
            },
        },
    },
    --#endregion
    --#region Large Gift
    ["Large Gift"] = {
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 500,
            },
        },
        {
            Type = "PetEgg",
            Weight = 5,
            Data = {
                PetEgg = "Common",
            },
        },
        {
            Type = "Clothing",
            Weight = 30,
            Data = {
                Clothing = {
                    Backpack = {
                        "Brown_Backpack",
                    },
                    Hat = {
                        "Pizza_Chef_Hat",

                        "Feather_Hat",
                        "Flower_Pot",

                        "Pink_Bunny_Ears",
                        "Pot",
                    },
                    Pants = {

                        "Pink_Skirt",
                        "Student_Pants",

                        "Pink_Pants",
                    },
                    Shirt = {

                        "Pink_Spotted_Shirt",
                        "Yellow_Diver_Tank",

                        "Purple_Shirt",
                        "Orange_Gradient_Shirt",
                    },
                    Shoes = {

                        "Tailor_Slippers",
                    },
                },
            },
        },
        {
            Type = "House",
            Weight = 60,
            Data = {
                House = {
                    Furniture = {
                        "Balloons",
                        "Pizza_Oven",
                        "Gaming_Chair",
                    },
                },
            },
        },
    },
    --#endregion
    --#region Rare Gift
    ["Rare Gift"] = {
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 750,
            },
        },
        {
            Type = "PetEgg",
            Weight = 5,
            Data = {
                PetEgg = "Rare",
            },
        },
        {
            Type = "Outfit",
            Weight = 30,
            Data = {
                Outfit = {
                    "Gentlepenguin",
                    "Sailor",
                    "Waiter",
                },
            },
        },
        {
            Type = "House",
            Weight = 60,
            Data = {
                House = {
                    Furniture = {
                        "Hockey_Table",
                        "STONE_LANTERN",
                        "Entertainment_Center",
                    },
                },
            },
        },
    },
    --#endregion
    --#region Extraordinary Gift
    ["Extraordinary Gift"] = {
        {
            Type = "Coins",
            Weight = 5,
            Data = {
                Coins = 1000,
            },
        },
        {
            Type = "PetEgg",
            Weight = 5,
            Data = {
                PetEgg = "Rare",
            },
        },
        {
            Type = "Outfit",
            Weight = 30,
            Data = {
                Outfit = {
                    "Pizza_Chef",
                    "Bill",
                    "Student",
                },
            },
        },
        {
            Type = "House",
            Weight = 60,
            Data = {
                House = {
                    Furniture = {
                        "COMPUTER_TABLE",
                        "Couch_03",
                        "Speakers",
                    },
                },
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
