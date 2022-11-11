local ZoneSettings: { [string]: { [string]: ZoneSettings } } = {
    -- Rooms
    Room = {
        PizzaPlace = {
            Music = "PizzaPlace",
        },
        Boardwalk = {
            Music = "Boardwalk",
        },
    },

    -- Minigames
    Minigame = {
        -- Pizza
        Pizza = {
            Lighting = {
                Ambient = Color3.fromRGB(130, 120, 113),
            },
            DisableCollisions = true,
            Music = false,
        },
    },
}

export type ZoneSettings = {
    Lighting: {
        Ambient: Color3?,
    }?,
    DisableCollisions: boolean?,
    Music: boolean | string?, -- Set to false to disable music. nil/true for MainTheme.
}

return ZoneSettings
