local ZoneConstants = {}

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

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

--!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)
ZoneConstants.StreamingTargetRadius = 1024

-- Attribute we set on an instance when it has children that are BaseParts. Used for the client to detect if a zone is fully loaded in yet
ZoneConstants.AttributeBasePartTotal = "_ZoneTotalBaseParts"

return ZoneConstants
