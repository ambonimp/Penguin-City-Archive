--[[
    Gives a player a house when they join, and empties it when they leave. Handles all housing server/client communication with plots and furniture

    Terminology:
        Plot - A container for a house, can change on the server when the player wants to change their house's location
        House - Thing that actually belongs to the player. .Exterior teleports the player to the interior and the interior contains all of the player's house objects.
]]

local PlotService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ProductService = require(Paths.Server.Products.ProductService)
local Remotes = require(Paths.Shared.Remotes)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local DataService = require(Paths.Server.Data.DataService)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local HouseObjects = require(Paths.Shared.Constants.HouseObjects)
local PlayerService = require(Paths.Server.PlayerService)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

type FurnitureMetadata = {
    Name: string,
    Position: Vector3,
    Rotation: Vector3,
    Color: { Color3 },
    Normal: Vector3,
}

type WallpaperMetadata = {
    Name: string,
}
type FloorMetadata = {
    Name: string,
}

local assets: Folder = ReplicatedStorage.Assets.Housing

local plots: { [string]: { [Player]: Model } } = {
    Exterior = {},
    Interior = {},
}

local exteriorPlots = workspace.Rooms.Neighborhood:WaitForChild(HousingConstants.ExteriorFolderName)
local neighborhoodZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Neighborhood)

-------------------------------------------------------------------------------
-- PLOT METHODS
-------------------------------------------------------------------------------
--Finds an empty plot for exterior/interior
local function findEmptyPlot(type: string)
    if type == HousingConstants.ExteriorType then
        for _, model: Model in exteriorPlots:GetChildren() do
            if not model:GetAttribute(HousingConstants.PlotOwner) then
                return model
            end
        end
    elseif type == HousingConstants.InteriorType then
        local interiorModel = assets.InteriorPlot:Clone()
        return interiorModel
    else
        warn(("Unknown house type %q"):format(type))
    end
end

-- Returns a player's plot
local function getPlot(player: Player, type: string): Model | nil
    -- RETURN: Player doesn't have a plot
    if not player:GetAttribute(type) then
        return
    end

    return plots[type][player]
end

local function checkPositionIsWithinBounds(player: Player, position: Vector3): boolean
    local plot = getPlot(player, HousingConstants.InteriorType)

    local Floor = plot:FindFirstChildOfClass("Model")
    if Floor then
        Floor = Floor.Floor
    end
    local houseCFrame = CFrame.new(plot.Origin.Position)

    position = (houseCFrame * CFrame.new(position)).Position

    local boundsMin = Floor.Position - Vector3.new(Floor.Size.X / 2, 15, Floor.Size.Z / 2)
    local boundsMax = Floor.Position + Vector3.new(Floor.Size.X / 2, 300, Floor.Size.Z / 2)

    return (position.X >= boundsMin.X and position.X <= boundsMax.X)
        and (position.Y >= boundsMin.Y and position.Y <= boundsMax.Y)
        and (position.Z >= boundsMin.Z and position.Z <= boundsMax.Z)
end

-------------------------------------------------------------------------------
-- INTERIOR OBJECTS METHODS
-------------------------------------------------------------------------------
local function calculateCf(oldCf, surfacePos, normal)
    return HousingConstants.CalculateObjectCFrame(oldCf, surfacePos, normal)
end

local function placeFurniture(player, object: Model, metadata: FurnitureMetadata): boolean
    local plot = getPlot(player, HousingConstants.InteriorType)

    local houseCFrame = CFrame.new(plot.Origin.Position)

    local position = metadata.Position -- Local, relative to house cframe
    local rotation = metadata.Rotation
    local colors = metadata.Color
    local normal = metadata.Normal

    local cf = houseCFrame
        * calculateCf(
            CFrame.new(position) * CFrame.Angles(0, rotation.Y, 0) * CFrame.new(0, object:GetExtentsSize().Y / 2, 0),
            position,
            normal
        )
    object:PivotTo(cf)
    object.Parent = plot.Furniture

    for id, color in colors do
        if object:FindFirstChild("Color" .. id) then
            for _, part: BasePart in pairs(object:FindFirstChild("Color" .. id):GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
        end
    end

    return true
end

local function updateFurniture(player, object: Model, metadata: FurnitureMetadata): DataUtil.Store?
    if placeFurniture(player, object, metadata) then
        local data = {
            Name = metadata.Name,
            Position = DataUtil.serializeValue(metadata.Position),
            Rotation = DataUtil.serializeValue(metadata.Rotation),
            Color = {},
            Normal = DataUtil.serializeValue(metadata.Normal),
        }

        for _, color in metadata.Color do
            table.insert(data.Color, DataUtil.serializeValue(color))
        end
        return data
    end
end

-------------------------------------------------------------------------------
-- HOUSE METHODS
-------------------------------------------------------------------------------
-- Loads a house interior or exterior inside their plot
local function loadHouse(player: Player, plot: Model, type: string)
    plot:SetAttribute(HousingConstants.PlotOwner, player.UserId)
    plots[type][player] = plot

    local blueprint = DataService.get(player, "House.Blueprint")

    local model = assets[type .. "s"]:FindFirstChild(blueprint):Clone()
    model:PivotTo(plot.Origin.CFrame)
    model.Parent = plot

    --Sets the location as an attribute to easily be retrieved by Clients
    player:SetAttribute(type, model.Spawn.Position)

    if type == HousingConstants.InteriorType then
        -- Load objects in the house
        for id, store in pairs(DataService.get(player, "House.Furniture")) do
            local name = store.Name
            local objectTemplate = assets.Furniture:FindFirstChild(name)

            if objectTemplate then
                local object = objectTemplate:Clone()
                object.Name = id
                local data = {
                    Name = store.Name,
                    Position = DataUtil.deserializeValue(store.Position, Vector3),
                    Rotation = DataUtil.deserializeValue(store.Rotation, Vector3),
                    Color = {},
                    Normal = DataUtil.deserializeValue(store.Normal, Vector3),
                }
                for _, color in pairs(store.Color) do
                    table.insert(data.Color, DataUtil.deserializeValue(color, Color3))
                end
                placeFurniture(player, object, data)
            else
                warn(("Furniture %s did not load because model no longer exists"):format(name))
            end
        end
    elseif type == HousingConstants.ExteriorType then
        --Handle entering and exiting houses
        local zone = ZoneUtil.houseInteriorZone(player)

        -- Departure
        local entrancePart: BasePart = model.Entrance
        entrancePart.Name = zone.ZoneType
        entrancePart.Parent = game.Workspace.Rooms.Neighborhood.ZoneInstances.RoomDepartures

        -- Arrival
        local spawnPart = model.Spawn
        spawnPart.Name = zone.ZoneType
        spawnPart.Parent = game.Workspace.Rooms.Neighborhood.ZoneInstances.RoomArrivals

        -- Cleanup
        InstanceUtil.onDestroyed(model, function()
            entrancePart:Destroy()
            spawnPart:Destroy()
        end)
    end
end

-- Unloads  a house interior or exterior
-- IsChange guarantees that another player can't snatch your plot if the hosue is being changed
local function unloadHouse(player: Player, plot: Model, type: string, isChange: true?)
    -- RETURN: Nothing to unload
    if not plot then
        return
    end

    -- HousingConstants.InteriorType is handled by the ZoneService
    if type == HousingConstants.ExteriorType then
        if plot then
            if not isChange then
                plot:SetAttribute(HousingConstants.PlotOwner, nil)
            end

            if plot:FindFirstChildOfClass("Model") then
                plot:FindFirstChildOfClass("Model"):Destroy()
            end
        end
    else
        if plot:FindFirstChild("Furniture") then
            plot.Furniture:ClearAllChildren()
        end
    end

    if not isChange then
        plots[type][player] = nil
    end
end

-------------------------------------------------------------------------------
-- LOADING/ UNLOADING
-------------------------------------------------------------------------------
--Runs once per player on join
function PlotService.loadPlayer(player: Player)
    local exteriorPlot: Model = findEmptyPlot(HousingConstants.ExteriorType)
    local interiorPlot: Model = findEmptyPlot(HousingConstants.InteriorType)

    loadHouse(player, exteriorPlot, HousingConstants.ExteriorType)
    loadHouse(player, interiorPlot, HousingConstants.InteriorType)

    -- Create zone for interior
    local houseInteriorZone = ZoneUtil.houseInteriorZone(player)

    local spawnPart = interiorPlot:FindFirstChildOfClass("Model").Spawn

    local destroyFunction = ZoneService.createZone(houseInteriorZone, { interiorPlot }, spawnPart)
    PlayerService.getPlayerMaid(player):GiveTask(destroyFunction)

    local exitPart = interiorPlot:FindFirstChildOfClass("Model").Exit
    exitPart.Name = ZoneConstants.ZoneType.Room.Neighborhood
    exitPart.Parent = ZoneUtil.getZoneInstances(houseInteriorZone).RoomDepartures
end

--Handles removing models and resetting plots on leave
function PlotService.unloadPlayer(player: Player)
    local exteriorPlot: Model = getPlot(player, HousingConstants.ExteriorType)
    local interiorPlot: Model = getPlot(player, HousingConstants.InteriorType)

    unloadHouse(player, exteriorPlot, HousingConstants.ExteriorType)
    unloadHouse(player, interiorPlot, HousingConstants.InteriorType)
end

-------------------------------------------------------------------------------
-- SERVER/CLIENT COMMUNICATION
-------------------------------------------------------------------------------
Remotes.bindEvents({
    PlaceHouseObject = function(player: Player, type: string, metadata: FurnitureMetadata | WallpaperMetadata | FloorMetadata)
        local product = ProductUtil.getHouseObjectProduct("Furniture", metadata.Name)
        if not ProductService.canPlaceHouseProduct(player, product) then
            return -- doesn't have enough of the iem to place
        end
        local typeConstants = HouseObjects[type]
        -- RETURN: Object isn't valid
        if not typeConstants then
            return
        end

        local name = metadata.Name
        local objectConstants = typeConstants.Objects[name]
        -- RETURN: Object isn't valid
        if not objectConstants then
            return
        end

        -- Handlers
        if type == "Furniture" then
            local withinBounds = checkPositionIsWithinBounds(player, metadata.Position)
            if withinBounds then
                local id = DataService.getAppendageKey(player, "House.Furniture")
                local object = assets[type]:FindFirstChild(name):Clone()
                object.Name = id
                ProductService.addProduct(player, product, -1)
                local store = updateFurniture(player, object, metadata) -- Flag for valid placement
                if store then
                    DataService.set(player, "House.Furniture." .. id, store, "OnFurniturePlaced", { Id = id })
                end
            end
        end
    end,

    -- Furniture
    RemoveFurniture = function(player: Player, id: string)
        local plot = getPlot(player, HousingConstants.InteriorType)

        local store = DataService.get(player, "House.Furniture")
        -- RETURN: ITEM DOES NOT EXIST
        if not store[id] then
            return
        end
        local product = ProductUtil.getHouseObjectProduct("Furniture", store[id].Name)
        ProductService.addProduct(player, product, 1)
        plot.Furniture[id]:Destroy()
        DataService.set(player, "House.Furniture." .. id, nil, "OnFurnitureRemoved", {
            Id = id,
        })
    end,
    UpdateFurniture = function(player: Player, id: string, metadata: FurnitureMetadata)
        local plot = getPlot(player, HousingConstants.InteriorType)
        local store = DataService.get(player, "House.Furniture")

        -- RETURN: Object does not exist
        if store[id] then
            local withinBounds = checkPositionIsWithinBounds(player, metadata.Position)
            if withinBounds then
                local object = plot.Furniture[id]

                local newStore = updateFurniture(player, object, metadata) -- Flag for valid placement
                if newStore then
                    DataService.set(player, "House.Furniture." .. id, newStore, "OnFurnitureUpdated", { Id = id })
                end
            end
        end
    end,

    -- Blueprint
    ChangeBlueprint = function(player: Player, name: string) -- TODO: Check for ownership
        local interiorPlot = getPlot(player, HousingConstants.ExteriorType)
        local exteriorPlot = getPlot(player, HousingConstants.InteriorType)

        -- Teleport player our of house interior if they're there
        if ZoneUtil.zonesMatch(ZoneService.getPlayerZone(player), ZoneUtil.houseInteriorZone(player)) then
            -- RETURN: Teleport not a success
            if not ZoneService.teleportPlayerToZone(player, neighborhoodZone) then
                return
            end
        end

        local blueprintInfo = HouseObjects.Blueprint[name]
        if blueprintInfo then
            unloadHouse(player, exteriorPlot, HousingConstants.ExteriorType, true)
            unloadHouse(player, interiorPlot, HousingConstants.InteriorType, true)

            DataService.set(player, "House.Blueprint", name, "HouseBlueprintUpdated")
            loadHouse(player, exteriorPlot, HousingConstants.ExteriorType)
            loadHouse(player, exteriorPlot, HousingConstants.ExteriorType)
        end
    end,
})

return PlotService
