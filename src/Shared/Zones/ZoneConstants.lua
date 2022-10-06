local ZoneConstants = {}

export type PlayerZoneState = {
    Room: {
        Id: string,
        Metadata: table?,
    },
    Minigame: {
        Id: string?,
        Metadata: table?,
    },
}

export type Zone = {
    ZoneType: string,
    ZoneId: string,
}

ZoneConstants.ZoneType = {
    Room = "Room",
    Minigame = "Minigame",
}
ZoneConstants.ZoneId = {
    Room = {
        Start = "Start",
        Narnia = "Narnia",
    },
    Minigame = {
        Pizza = "Pizza",
    },
}

local defaultPlayerZoneState: PlayerZoneState = {
    Room = {
        Id = ZoneConstants.ZoneId.Room.Start,
    },
    Minigame = {},
}
ZoneConstants.DefaultPlayerZoneState = defaultPlayerZoneState

return ZoneConstants
