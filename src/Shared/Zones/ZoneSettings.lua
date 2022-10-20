local ZoneSettings: { [string]: { [string]: ZoneSettings } } = {
    -- Rooms
    Room = {},

    -- Minigames
    Minigame = {
        -- Pizza
        Pizza = {
            Lighting = {
                Ambient = Color3.fromRGB(130, 120, 113),
            },
            DisableCollisions = true,
        },
    },
}

export type ZoneSettings = {
    Lighting: {
        Ambient: Color3?,
    }?,
    DisableCollisions: boolean?,
}

return ZoneSettings
