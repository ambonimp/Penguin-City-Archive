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
        PizzaFiasco = {
            Lighting = {
                Ambient = Color3.fromRGB(190, 190, 161),
                Brightness = 3,
                ColorShift_Top = Color3.fromRGB(0, 0, 0),
                ClockTime = 14,
                GeographicLatitude = 149,
                ExposureCompensation = 0,
            },
            DisableCollisions = true,
            Music = false,
            DisableCoreGui = true,
        },
        -- IceCreamExtravaganza
        IceCreamExtravaganza = {
            Lighting = {
                Ambient = Color3.fromRGB(255, 128, 130),
            },
            DisableCollisions = false,
            Music = false,
        },
        -- SledRace
        SledRace = {
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
    DisableCoreGui: boolean?,
}

return ZoneSettings
