local ZoneConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

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
-- Internal Methods
-------------------------------------------------------------------------------

-- Gets our constants directly out of studio
local function getRoomTypes()
    local roomTypes = setmetatable({}, {
        __index = function(_, index)
            warn(("Bad RoomType %q"):format(index))
        end,
    }) :: { [string]: string }

    local function addRoom(roomFolder: Folder)
        local roomType = roomFolder.Name
        if not tonumber(roomType) then -- Exclude houseInteriorZones
            roomTypes[roomType] = roomType
        end
    end

    local rooms: Folder = game.Workspace.Rooms
    for _, child in pairs(rooms:GetChildren()) do
        addRoom(child)
    end
    rooms.ChildAdded:Connect(addRoom)

    return roomTypes
end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ZoneConstants.ZoneCategory = {
    Room = "Room",
    Minigame = "Minigame",
}
setmetatable(ZoneConstants.ZoneCategory, {
    __index = function(_, index)
        warn(("Bad ZoneCategory %q"):format(index))
    end,
})

ZoneConstants.ZoneType = {
    Room = getRoomTypes(),
    Minigame = MinigameConstants.Minigames,
}
setmetatable(ZoneConstants.ZoneCategory, {
    __index = function(_, index)
        warn(("Bad ZoneType %q"):format(index))
    end,
})

ZoneConstants.ZoneInstances = {
    FolderNames = { "MinigameDepartures", "MinigameArrivals", "RoomArrivals", "RoomDepartures" },
}

ZoneConstants.PlayerDefaultRoom = ZoneConstants.ZoneType.Room.ClothingStore

--!! Must be manually defined, we cannot read this property on Workspace (so clever Roblox well done)
ZoneConstants.StreamingTargetRadius = 5300

-- Attribute we set on an instance when it has children that are BaseParts. Used for the client to detect if a zone is fully loaded in yet
ZoneConstants.AttributeBasePartTotal = "_ZoneTotalBaseParts"
ZoneConstants.AttributeIsProcessed = "_ZoneIsProcessed"
-- How long between informing client they're being teleported, and actually teleporting (be duration of fade in on transition)
ZoneConstants.TeleportBuffer = 0.5
ZoneConstants.DoDebug = false

-- Some zones (famously Boardwalk) will regularly be waiting on 1 part to load. We *do* assume that all parts are loaded before declaring a zone loaded,
-- but it affects the user experience when we have long loading times. We allow a small buffer for Rooms to offset this. We have *not* enabled
-- this behaviour for minigames, as minigames are much more likely to need to run routines based off the existence of specific instances
ZoneConstants.DeclareRoomZonesAsLoadedWithMissingParts = 3

-------------------------------------------------------------------------------
-- Cosmetics
-------------------------------------------------------------------------------

ZoneConstants.Cosmetics = {
    Tags = {
        AnimatedFlag = "AnimatedFlag",
        WaterAnimator = "AnimateWater",
        DiscoBall = "DiscoBall",
        DanceFloor = "DanceFloor",
        Swing = "Swing",
    },
    Disco = {
        ColorPartName = "ColorPart",
        HitboxPartName = "Hitbox",
    },
}

return ZoneConstants
