local ZoneUtil = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ZoneSettings = require(ReplicatedStorage.Shared.Zones.ZoneSettings)
local PropertyStack = require(ReplicatedStorage.Shared.PropertyStack)

export type ZoneInstances = {
    Spawnpoint: BasePart?,
    MinigameDepartures: Folder?,
    MinigameArrivals: Folder?,
    RoomArrivals: Folder?,
    RoomDepartures: Folder?,
}

local MAX_YIELD_TIME_INSTANCE_LOADING = 20

-------------------------------------------------------------------------------
-- Zone Datastructure Generators
-------------------------------------------------------------------------------

function ZoneUtil.zone(zoneCategory: string, zoneType: string, zoneId: string?)
    local zone: ZoneConstants.Zone = {
        ZoneCategory = zoneCategory,
        ZoneType = zoneType,
        ZoneId = zoneId,
    }

    return zone
end

function ZoneUtil.houseInteriorZone(player: Player)
    return ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, tostring(player.UserId))
end

function ZoneUtil.defaultZone()
    return ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.PlayerDefaultRoom)
end

-------------------------------------------------------------------------------
-- Zone Querying
-------------------------------------------------------------------------------
function ZoneUtil.getZoneName(zone: ZoneConstants.Zone): string
    local name: string = zone.ZoneType
    local id: string? = zone.ZoneId
    if id then
        name = name .. "(" .. id .. ")"
    end
    return name
end

function ZoneUtil.getZoneTypeAndIdFromName(name: string)
    local zoneType = name:match("[%-]?[%w]+")
    local zoneId = name:gsub(zoneType, ""):match("[%-]?[%w]+")

    return zoneType, zoneId
end

function ZoneUtil.zonesMatch(zone1: ZoneConstants.Zone, zone2: ZoneConstants.Zone)
    return zone1.ZoneType == zone2.ZoneType and zone1.ZoneId == zone2.ZoneId and true or false
end

function ZoneUtil.isHouseInteriorZone(zone: ZoneConstants.Zone)
    local userId = tonumber(zone.ZoneType)
    return userId and game.Players:GetPlayerByUserId(userId) and true or false
end

function ZoneUtil.doesZoneExist(zone: ZoneConstants.Zone?)
    return if zone and ZoneUtil.getZoneCategoryDirectory(zone.ZoneCategory):FindFirstChild(ZoneUtil.getZoneName(zone)) then true else false
end

function ZoneUtil.getHouseInteriorZoneOwner(zone: ZoneConstants.Zone)
    -- RETURN: Not a house zone
    if not ZoneUtil.isHouseInteriorZone(zone) then
        return nil
    end

    local userId = tonumber(zone.ZoneType)
    return Players:GetPlayerByUserId(userId)
end

-------------------------------------------------------------------------------
-- Models / Instances
-------------------------------------------------------------------------------
function ZoneUtil.getZoneCategoryDirectory(zoneCategory: string)
    if zoneCategory == ZoneConstants.ZoneCategory.Room then
        return game.Workspace.Rooms
    elseif zoneCategory == ZoneConstants.ZoneCategory.Minigame then
        return game.Workspace.Minigames
    else
        error(("ZoneCategory %q wat"):format(zoneCategory))
    end
end

function ZoneUtil.getZoneModel(zone: ZoneConstants.Zone)
    return ZoneUtil.getZoneCategoryDirectory(zone.ZoneCategory)[ZoneUtil.getZoneName(zone)]
end

function ZoneUtil.getZoneInstances(zone: ZoneConstants.Zone)
    local instance = ZoneUtil.getZoneModel(zone).ZoneInstances
    local zoneInstances: ZoneInstances = {
        Spawnpoint = instance:FindFirstChild("Spawnpoint"),
        MinigameDepartures = instance:FindFirstChild("MinigameDepartures"),
        MinigameArrivals = instance:FindFirstChild("MinigameArrivals"),
        RoomArrivals = instance:FindFirstChild("RoomArrivals"),
        RoomDepartures = instance:FindFirstChild("RoomDepartures"),
    }

    return zoneInstances
end

function ZoneUtil.getZoneFromZoneModel(zoneModel: Model)
    local zoneCategory = zoneModel.Parent == game.Workspace.Rooms and ZoneConstants.ZoneCategory.Room
        or zoneModel.Parent == game.Workspace.Minigames and ZoneConstants.ZoneCategory.Minigame
        or error(("Could not infer ZoneCategory from %q"):format(zoneModel:GetFullName()))

    return ZoneUtil.zone(zoneCategory, ZoneUtil.getZoneTypeAndIdFromName(zoneModel.Name))
end

-------------------------------------------------------------------------------
-- ZoneInstances
-------------------------------------------------------------------------------

-- Returns a spawnpoint in the context of the zone we're leaving
function ZoneUtil.getSpawnpoint(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    local arrivals = ZoneUtil.getArrivals(toZone, fromZone.ZoneCategory)
    if arrivals then
        local arrivalSpawnpoint = arrivals:FindFirstChild(fromZone.ZoneType)
        if arrivalSpawnpoint then
            return arrivalSpawnpoint
        end
    end

    return ZoneUtil.getZoneInstances(toZone).Spawnpoint
end

function ZoneUtil.getArrivals(zone: ZoneConstants.Zone, zoneCategory: string)
    return ZoneUtil.getZoneInstances(zone)[("%sArrivals"):format(zoneCategory)]
end

function ZoneUtil.getDepartures(zone: ZoneConstants.Zone, zoneCategory: string)
    return ZoneUtil.getZoneInstances(zone)[("%sDepartures"):format(zoneCategory)]
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

function ZoneUtil.getSettings(zone: ZoneConstants.Zone)
    return ZoneSettings[zone.ZoneCategory][zone.ZoneType] or nil
end

function ZoneUtil.applySettings(zone: ZoneConstants.Zone)
    local settings = ZoneUtil.getSettings(zone)
    if settings then
        local key = zone.ZoneCategory .. zone.ZoneType

        -- Lighting
        if settings.Lighting then
            PropertyStack.setProperties(Lighting, settings.Lighting, key)
        end
    end
end

function ZoneUtil.revertSettings(zone: ZoneConstants.Zone)
    local settings = ZoneUtil.getSettings(zone)
    if settings then
        local key = zone.ZoneCategory .. zone.ZoneType

        -- Lighting
        if settings.Lighting then
            PropertyStack.clearProperties(Lighting, settings.Lighting, key)
        end
    end
end

-------------------------------------------------------------------------------
-- Streaming
-------------------------------------------------------------------------------

local function countBasePartsUnderInstance(instance: Instance)
    local totalBaseParts = 0
    for _, child in pairs(instance:GetChildren()) do
        if child:IsA("BasePart") then
            totalBaseParts += 1
        end
    end

    return totalBaseParts
end

--[[
    **Server Only**

    Will keep this instance heirachy updated such that related streaming functions can be called on the client
]]
function ZoneUtil.writeBasepartTotals(instance: Instance)
    -- ERROR: Server only
    if not RunService:IsServer() then
        error("Server Only")
    end

    -- Tot up our baseparts
    local totalBaseParts = 0
    for _, child in pairs(instance:GetChildren()) do
        if child:IsA("BasePart") then
            totalBaseParts += 1

            -- ERROR: Nested Basepart!
            local nestedBasePart = child:FindFirstAncestorWhichIsA("BasePart")
            if nestedBasePart then
                error(("%s has nested BasePart(s) (%s)"):format(instance:GetFullName(), nestedBasePart:GetFullName()))
            end
        else
            ZoneUtil.writeBasepartTotals(child)
        end
    end

    -- Write
    instance:SetAttribute(ZoneConstants.AttributeBasePartTotal, totalBaseParts)

    -- Handle new/old children
    if not instance:GetAttribute(ZoneConstants.AttributeIsProcessed) then
        instance.ChildAdded:Connect(function()
            task.wait() -- Breathing room for full heirachy to get loaded
            ZoneUtil.writeBasepartTotals(instance)
        end)
        instance.ChildRemoved:Connect(function()
            ZoneUtil.writeBasepartTotals(instance)
        end)

        instance:SetAttribute(ZoneConstants.AttributeIsProcessed, true)
    end
end

--[[
    **Client Only**

    Returns true if everything under this instance is loaded!
    - Will not work as intended if `ZoneUtil.writeBasepartTotals` has not been invoked on this structure.
]]
function ZoneUtil.areAllBasePartsLoaded(instance: Instance)
    -- ERROR: Client Only
    if not RunService:IsClient() then
        return
    end

    local instances: { Instance } = instance:GetDescendants()
    table.insert(instances, 1, instance)

    for _, someInstance in pairs(instances) do
        if not someInstance:IsA("BasePart") then
            local serverTotal = someInstance:GetAttribute(ZoneConstants.AttributeBasePartTotal)

            -- Query + Compare if more than 0
            if serverTotal and serverTotal > 0 then
                local clientTotal = countBasePartsUnderInstance(someInstance)
                if serverTotal > clientTotal then
                    return false
                end
            end
        end
    end

    return true
end

--[[
    **Client Only**

    Returns true if success; false otherwise
    - Will not work as intended if `ZoneUtil.writeBasepartTotals` has not been invoked on this structure.
]]
function ZoneUtil.waitForInstanceToLoad(instance: Instance)
    -- ERROR: Client Only
    if not RunService:IsClient() then
        return
    end

    local endTick = tick() + MAX_YIELD_TIME_INSTANCE_LOADING
    while tick() < endTick do
        local isLoaded = ZoneUtil.areAllBasePartsLoaded(instance)
        if isLoaded then
            task.wait() -- Give client threads time to catch up
            return true
        end
        task.wait(1)
    end

    return false
end

-------------------------------------------------------------------------------
-- Cmdr
-------------------------------------------------------------------------------
function ZoneUtil.getZoneTypeCmdrArgument(zoneCategoryArgument)
    local zoneCategory = zoneCategoryArgument:GetValue()
    return {
        Type = ZoneUtil.getZoneTypeCmdrTypeName(zoneCategory),
        Name = "zoneType",
        Description = ("zoneType (%s)"):format(zoneCategory),
    }
end

function ZoneUtil.getZoneTypeCmdrTypeName(zoneCategory: string)
    return StringUtil.toCamelCase(("%sZoneType"):format(zoneCategory))
end

return ZoneUtil
