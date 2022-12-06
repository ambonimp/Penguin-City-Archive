local ZoneSettings: { [string]: { [string]: ZoneSettings } } = {
    -- Rooms
    Room = {
        PizzaPlace = {
            Music = "PizzaPlace",
        },
        Boardwalk = {
            Music = "Boardwalk",
        },
        SkiHill = {
            Music = "SkiHill",
            Ambience = { "WindAndBirds" },
            IsWindy = true,
        },
        School = {
            Music = "School",
        },
        HockeyStadium = {
            Music = "HockeyStadium",
        },
        ClothingStore = {
            Music = "ClothingStore",
        },
        Hospital = {
            Music = "Hospital",
        },
        NightClub = {
            Music = "NightClub",
        },
        CoffeeShop = {
            Music = "CoffeeShop",
        },
        Town = {},
    },

    -- Minigames
    Minigame = {
        -- Pizza
        Pizza = {
            Lighting = {
                Ambient = Color3.fromRGB(190, 136, 97),
                Brightness = 1.6,
                ColorShift_Top = Color3.fromRGB(0, 0, 0),
                ClockTime = 11,
                GeographicLatitude = 149,
                ExposureCompensation = 0,
            },
            DisableCollisions = true,
            Music = false,
        },
    },
}

export type ZoneSettings = {
    Lighting: {
        [string]: any,
    }?,
    DisableCollisions: boolean?,
    Music: boolean | string?, -- Set to false to disable music. nil/true for MainTheme.
    Ambience: { string }?, -- Names of Sounds to play
    IsWindy: boolean?,
}

return ZoneSettings
