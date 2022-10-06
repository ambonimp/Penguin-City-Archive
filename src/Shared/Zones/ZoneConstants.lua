local ZoneConstants = {}

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

export type PlayerZoneState = {
    RoomId: string,
    MinigameId: string?,
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
        Start = "Start",
        Narnia = "Narnia",
        Neighborhood = "Neighborhood",
    },
    Minigame = {
        Pizza = "Pizza",
    },
}

local defaultPlayerZoneState: PlayerZoneState = {
    RoomId = ZoneConstants.ZoneId.Room.Start,
    MinigameId = nil,
    TotalTeleports = 0,
}
ZoneConstants.DefaultPlayerZoneState = defaultPlayerZoneState

--!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)
ZoneConstants.StreamingTargetRadius = 1024

-- Attribute we set on an instance when it has children that are BaseParts. Used for the client to detect if a zone is fully loaded in yet
ZoneConstants.AttributeBasePartTotal = "_ZoneTotalBaseParts"
-- How long between informing client they're being teleported, and actually teleporting
ZoneConstants.TeleportBuffer = 1

ZoneConstants.DoDebug = true

return ZoneConstants
