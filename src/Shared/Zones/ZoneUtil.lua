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

function ZoneUtil.zone(zoneType: string, zoneId: string)
    local zone: ZoneConstants.Zone = {
        ZoneType = zoneType,
        ZoneId = zoneId,
    }

    return zone
end

function ZoneUtil.houseInteriorZone(player: Player)
    return ZoneUtil.zone(ZoneConstants.ZoneType.Room, tostring(player.UserId))
end

-------------------------------------------------------------------------------
-- Zone Querying
-------------------------------------------------------------------------------

function ZoneUtil.zonesMatch(zone1: ZoneConstants.Zone, zone2: ZoneConstants.Zone)
    return zone1.ZoneType == zone2.ZoneType and zone1.ZoneId == zone2.ZoneId and true or false
end

function ZoneUtil.isHouseInteriorZone(zone: ZoneConstants.Zone)
    local userId = tonumber(zone.ZoneId)
    return userId and game.Players:GetPlayerByUserId(userId) and true or false
end

function ZoneUtil.doesZoneExist(zone: ZoneConstants.Zone)
    return ZoneUtil.getZoneTypeDirectory(zone.ZoneType):FindFirstChild(zone.ZoneId) and true or false
end

function ZoneUtil.getHouseInteriorZoneOwner(zone: ZoneConstants.Zone)
    -- RETURN: Not a house zone
    if not ZoneUtil.isHouseInteriorZone(zone) then
        return nil
    end

    local userId = tonumber(zone.ZoneId)
    return Players:GetPlayerByUserId(userId)
end

-------------------------------------------------------------------------------
-- Models / Instances
-------------------------------------------------------------------------------

function ZoneUtil.getZoneTypeDirectory(zoneType: string)
    if zoneType == ZoneConstants.ZoneType.Room then
        return game.Workspace.Rooms
    elseif zoneType == ZoneConstants.ZoneType.Minigame then
        return game.Workspace.Minigames
    else
        error(("ZoneType %q wat"):format(zoneType))
    end
end

function ZoneUtil.getZoneModel(zone: ZoneConstants.Zone): Model
    return ZoneUtil.getZoneTypeDirectory(zone.ZoneType)[zone.ZoneId]
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
    local zoneType = zoneModel.Parent == game.Workspace.Rooms and ZoneConstants.ZoneType.Room
        or zoneModel.Parent == game.Workspace.Minigames and ZoneConstants.ZoneType.Minigame
        or error(("Could not infer ZoneType from %q"):format(zoneModel:GetFullName()))
    local zoneId = zoneModel.Name
    return ZoneUtil.zone(zoneType, zoneId)
end

-------------------------------------------------------------------------------
-- ZoneInstances
-------------------------------------------------------------------------------

-- Returns a spawnpoint in the context of the zone we're leaving
function ZoneUtil.getSpawnpoint(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    local arrivals = ZoneUtil.getArrivals(toZone, fromZone.ZoneType)
    if arrivals then
        local arrivalSpawnpoint = arrivals:FindFirstChild(fromZone.ZoneId)
        if arrivalSpawnpoint then
            return arrivalSpawnpoint
        end
    end

    return ZoneUtil.getZoneInstances(toZone).Spawnpoint
end

function ZoneUtil.getArrivals(zone: ZoneConstants.Zone, zoneType: string)
    return ZoneUtil.getZoneInstances(zone)[("%sArrivals"):format(zoneType)]
end

function ZoneUtil.getDepartures(zone: ZoneConstants.Zone, zoneType: string)
    return ZoneUtil.getZoneInstances(zone)[("%sDepartures"):format(zoneType)]
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

function ZoneUtil.getSettings(zone: ZoneConstants.Zone)
    return ZoneSettings[zone.ZoneType][zone.ZoneId] or nil
end

function ZoneUtil.applySettings(zone: ZoneConstants.Zone)
    local settings = ZoneUtil.getSettings(zone)
    if settings then
        local key = zone.ZoneType .. zone.ZoneId

        -- Lighting
        if settings.Lighting then
            PropertyStack.setProperties(Lighting, settings.Lighting, key)
        end
    end
end

function ZoneUtil.revertSettings(zone: ZoneConstants.Zone)
    local settings = ZoneUtil.getSettings(zone)
    if settings then
        local key = zone.ZoneType .. zone.ZoneId

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

function ZoneUtil.getZoneIdCmdrArgument(zoneTypeArgument)
    local zoneType = zoneTypeArgument:GetValue()
    return {
        Type = ZoneUtil.getZoneIdCmdrTypeName(zoneType),
        Name = "zoneId",
        Description = ("zoneId (%s)"):format(zoneType),
    }
end

function ZoneUtil.getZoneIdCmdrTypeName(zoneType: string)
    return StringUtil.toCamelCase(("%sZoneId"):format(zoneType))
end

return ZoneUtil
