local ZoneConstants = {}

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

export type PlayerZoneState = {
    RoomId: string,
    MinigameId: string?,
    IglooId: string?,
    TotalTeleports: number,
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
        Narnia = "Narnia",
        Neighborhood = "Neighborhood",
    },
    Minigame = {
        Pizza = "Pizza",
    },
}

local defaultPlayerZoneState: PlayerZoneState = {
    RoomId = ZoneConstants.ZoneId.Room.Neighborhood,
    TotalTeleports = 0,
}
ZoneConstants.DefaultPlayerZoneState = defaultPlayerZoneState

--!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)
ZoneConstants.StreamingTargetRadius = 2533

-- Attribute we set on an instance when it has children that are BaseParts. Used for the client to detect if a zone is fully loaded in yet
ZoneConstants.AttributeBasePartTotal = "_ZoneTotalBaseParts"
-- How long between informing client they're being teleported, and actually teleporting (be duration of fade in on transition)
ZoneConstants.TeleportBuffer = 0.5

ZoneConstants.DoDebug = false

ZoneConstants.GridPriority = {
    RoomsAndMinigames = 0,
    Igloos = 1,
}

return ZoneConstants
