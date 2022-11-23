local ZoneConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)

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
-- Internal Methods
-------------------------------------------------------------------------------

-- Gets our constants directly out of studio
local function getRoomIds()
    local roomIds = setmetatable({}, {
        __index = function(_, index)
            error(("Bad RoomId %q"):format(index))
        end,
    }) :: { [string]: string }

    local function addRoom(roomFolder: Folder)
        roomIds[roomFolder.Name] = roomFolder.Name
    end

    local rooms: Folder = game.Workspace.Rooms
    for _, child in pairs(rooms:GetChildren()) do
        addRoom(child)
    end
    rooms.ChildAdded:Connect(addRoom)

    return roomIds
end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ZoneConstants.ZoneType = {
    Room = "Room",
    Minigame = "Minigame",
}
ZoneConstants.ZoneId = {
    Room = getRoomIds(),
    Minigame = {
        Pizza = "Pizza",
    },
}

ZoneConstants.ZoneInstances = {
    FolderNames = { "MinigameDepartures", "MinigameArrivals", "RoomArrivals", "RoomDepartures" },
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
ZoneConstants.AttributeIsProcessed = "_ZoneIsProcessed"
-- How long between informing client they're being teleported, and actually teleporting (be duration of fade in on transition)
ZoneConstants.TeleportBuffer = 0.5

ZoneConstants.DoDebug = false

return ZoneConstants
