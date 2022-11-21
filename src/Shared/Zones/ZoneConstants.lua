local ZoneConstants = {}

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

export type Zone = {
    ZoneCategory: string,
    ZoneType: string,
    ZoneId: string?,
}

export type PlayerZoneState = {
    RoomZone: Zone?,
    MinigameZone: Zone?,
    IglooId: string?,
    TotalTeleports: number,
}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ZoneConstants.ZoneCategory = {
    Room = "Room",
    Minigame = "Minigame",
}
ZoneConstants.ZoneType = {
    Room = {
        Town = "Town",
        Neighborhood = "Neighborhood",
        SkiHill = "SkiHill",
        PizzaPlace = "PizzaPlace",
        CoffeeShop = "CoffeeShop",
        IceCreamShop = "IceCreamShop",
    },
    Minigame = {
        SledRace = "SledRace",
        IceCreamExtravaganza = "IceCreamExtravaganza",
        PizzaFiasco = "PizzaFiasco",
    },
}

ZoneConstants.ZoneInstances = {
    FolderNames = { "MinigameDepartures", "MinigameArrivals", "RoomArrivals", "RoomDepartures" },
}

ZoneConstants.DefaultPlayerZoneRoomState = ZoneConstants.ZoneType.Room.Neighborhood

--!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)
ZoneConstants.StreamingTargetRadius = 5300

-- Attribute we set on an instance when it has children that are BaseParts. Used for the client to detect if a zone is fully loaded in yet
ZoneConstants.AttributeBasePartTotal = "_ZoneTotalBaseParts"
ZoneConstants.AttributeIsProcessed = "_ZoneIsProcessed"
-- How long between informing client they're being teleported, and actually teleporting (be duration of fade in on transition)
ZoneConstants.TeleportBuffer = 0.5

ZoneConstants.DoDebug = false

return ZoneConstants
