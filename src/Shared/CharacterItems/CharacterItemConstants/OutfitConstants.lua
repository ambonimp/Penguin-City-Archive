local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local CharacterItemConstants = ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants
local ShirtConstants = require(CharacterItemConstants.ShirtConstants)
local PantsConstants = require(CharacterItemConstants.PantsConstants)
local HatConstants = require(CharacterItemConstants.HatConstants)
local ShoesConstants = require(CharacterItemConstants.ShoesConstants)

local OutfitConstants = {}

export type OutfitConstants = {
    Shirt: { string }?,
    Hat: { string }?,
    Pants: { string }?,
    Shoes: { string }?,
}
export type Item = {
    Price: number,
    Icon: string,
    Name: string,
    Items: OutfitConstants,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Farmer"] = {
    Name = "Farmer",
    Price = 165,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Flannel_Shirt.Name },
        Pants = { PantsConstants.Items.Overalls.Name },
        Hat = { HatConstants.Items.Farmer_Hat.Name },
    },
    ForSale = true,
}
items["Gentlepenguin"] = {
    Name = "Gentlepenguin",
    Price = 385,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Purple_Classy_Suit.Name },
        Pants = { PantsConstants.Items.Dark_Grey_Slacks.Name },
        Hat = { HatConstants.Items.Fancy_Top_Hat.Name },
        Shoes = { ShoesConstants.Items.Purple_Classy_Sneakers.Name },
    },
    ForSale = true,
}
items["Footballer"] = {
    Name = "Footballer",
    Price = 165,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Brazil_Jersey.Name },
        Pants = { PantsConstants.Items.Green_Pants.Name },
        Shoes = { ShoesConstants.Items.Black_Sneakers.Name },
    },
    ForSale = true,
}
items["Sailor"] = {
    Name = "Sailor",
    Price = 250,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Sailor_Shirt.Name },
        Pants = { PantsConstants.Items.White_Pants.Name },
        Hat = { HatConstants.Items.Sailor_Cap.Name },
    },
    ForSale = true,
}
items["Ice_Cream_Scopper"] = {
    Name = "Ice_Cream_Scopper",
    Price = 200,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Ice_Cream_Scooper_Shirt.Name },
        Pants = { PantsConstants.Items.Purple_Pants.Name },
        Hat = { HatConstants.Items.Ice_Cream_Hat.Name },
        Shoes = { ShoesConstants.Items.Pink_Sneakers.Name },
    },
    ForSale = true,
}
items["Boy"] = {
    Name = "Boy",
    Price = 0,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Classic_Teal_Sweater.Name },
        Pants = { PantsConstants.Items.Blue_Jeans.Name },
    },
    ForSale = true,
}
items["Girl"] = {
    Name = "Girl",
    Price = 0,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Classic_Pink_Sweater.Name },
        Pants = { PantsConstants.Items.Pink_Skirt.Name },
    },
    ForSale = true,
}
items["Waiter"] = {
    Name = "Waiter",
    Price = 175,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Waiter_Shirt.Name },
        Pants = { PantsConstants.Items.Bright_Red_Pants.Name },
        Shoes = { ShoesConstants.Items.Bright_Red_Shoes.Name },
    },
    ForSale = true,
}
items["Peach_Parisan"] = {
    Name = "Peach_Parisan",
    Price = 250,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Peach_Parisan_Blouse.Name },
        Pants = { PantsConstants.Items.Peach_Parisan_Skirt.Name },
        Hat = { HatConstants.Items.Peach_Bucket_Hat.Name },
        Shoes = { ShoesConstants.Items.Peach_Sneakers.Name },
    },
    ForSale = true,
}
items["Yellow_Parisan"] = {
    Name = "Yellow_Parisan",
    Price = 175,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Yellow_Blouse.Name },
        Pants = { PantsConstants.Items.Yellow_Skirt.Name },
    },
    ForSale = true,
}
items["Pizza_Chef"] = {
    Name = "Pizza_Chef",
    Price = 250,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Pizza_Chefs_Jacket.Name },
        Pants = { PantsConstants.Items.White_Pants.Name },
        Hat = { HatConstants.Items.Chef_Hat.Name },
    },
    ForSale = true,
}
items["Bill"] = {
    Name = "Bill",
    Price = 225,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Stripped_Yellow_Tee.Name },
        Pants = { PantsConstants.Items.Blue_Pants.Name },
        Hat = { HatConstants.Items.Pop_Cap.Name },
        Shoes = { ShoesConstants.Items.Dark_Red_Sneakers.Name },
    },
    ForSale = true,
}

items["Tailor"] = {
    Name = "Tailor",
    Price = 333,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Tailor_Suit.Name },
        Pants = { PantsConstants.Items.Dark_Grey_Slacks.Name },
        Hat = { HatConstants.Items.Clear_Glasses.Name },
        Shoes = { ShoesConstants.Items.Tailor_Slippers.Name },
    },
    ForSale = true,
}
items["Student"] = {
    Name = "Student",
    Price = 175,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Student_Shirt.Name },
        Pants = { PantsConstants.Items.Bright_Red_Pants.Name },
        Hat = { HatConstants.Items.Student_Cap.Name },
        Shoes = { ShoesConstants.Items.Black_Sneakers.Name },
    },
    ForSale = true,
}
items["Blue_Scooba_Diver"] = {
    Name = "Blue_Scooba_Diver",
    Price = 125,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Blue_Diver_Tank.Name },
        Pants = { PantsConstants.Items.Blue_Diver_Pants.Name },
        Hat = { HatConstants.Items.Blue_Snorkels.Name },
    },
    ForSale = true,
}
items["Yellow_Scooba_Diver"] = {
    Name = "Yellow_Scooba_Diver",
    Price = 125,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Yellow_Diver_Tank.Name },
        Pants = { PantsConstants.Items.Yellow_Diver_Pants.Name },
        Hat = { HatConstants.Items.Yellow_Snorkels.Name },
    },
    ForSale = true,
}
items["Pink_Scooba_Diver"] = {
    Name = "Pink_Scooba_Diver",
    Price = 125,
    Icon = nil,
    Items = {
        Shirt = { ShirtConstants.Items.Pink_Diver_Tank.Name },
        Pants = { PantsConstants.Items.Pink_Diver_Pants.Name },
        Hat = { HatConstants.Items.Pink_Snorkels.Name },
    },
    ForSale = true,
}

OutfitConstants.TabOrder = 4
OutfitConstants.TabIcon = Images.Icons.Outfit
OutfitConstants.SortOrder = Enum.SortOrder.LayoutOrder
OutfitConstants.MaxEquippables = 0
OutfitConstants.CanUnequip = false
OutfitConstants.Items = items

return OutfitConstants
