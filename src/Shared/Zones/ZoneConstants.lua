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

ZoneConstants.StreamingTargetRadius = 1024 --!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)

return ZoneConstants
