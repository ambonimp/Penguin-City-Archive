--[[
    Gives a player a house when they join, and empties it when they leave. Handles all housing server/client communication with plots and furniture

    Terminology:
        Plot - A container for a house, can change on the server when the player wants to change their house's location
        House - Thing that actually belongs to the player. .Exterior teleports the player to the interior and the interior contains all of the player's house objects.
]]

local PlotService = {}

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ProductService = require(Paths.Server.Products.ProductService)
local Remotes = require(Paths.Shared.Remotes)
local HousingUtil = require(Paths.Shared.Utils.HousingUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local FurnitureConstants = require(Paths.Shared.Constants.HouseObjects.FurnitureConstants)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local DataService = require(Paths.Server.Data.DataService)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local HouseObjects = require(Paths.Shared.Constants.HouseObjects)
local PlayerService = require(Paths.Server.PlayerService)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Signal = require(Paths.Shared.Signal)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Products = require(Paths.Shared.Products.Products)
local BlueprintConstants = require(Paths.Shared.Constants.HouseObjects.BlueprintConstants)

export type FurnitureMetadata = {
    Name: string,
    Position: Vector3,
    Rotation: Vector3,
    Color: { Color3 },
    Normal: Vector3,
}

export type WallpaperMetadata = {
    Name: string,
}
export type FloorMetadata = {
    Name: string,
}

export type Metadata = FurnitureMetadata | WallpaperMetadata | FloorMetadata

PlotService.ObjectPlaced = Signal.new() -- { player: Player, objectProduct: Products.Product, metadata: PlotService.Metadata }
PlotService.ObjectUpdated = Signal.new() -- { player: Player, objectProduct: Products.Product, oldMetadata: PlotService.Metadata, newMetadata: PlotService.Metadata }
PlotService.ObjectRemoved = Signal.new() -- { player: Player, objectProduct: Products.Product, metadata: PlotService.Metadata }
PlotService.BlueprintChanged = Signal.new() -- { player: Player, blueprintProduct: Products.Product, oldBlueprintProduct: Products.Product | nil }

local assets: Folder = ReplicatedStorage.Assets.Housing

local plots: { [string]: { [Player]: Model } } = {
    Exterior = {},
    Interior = {},
}

local newSpawnTable: { [Player]: ((newSpawn: BasePart) -> ()) } = {}

local exteriorPlots = workspace.Rooms.Neighborhood:WaitForChild(HousingConstants.ExteriorFolderName)

-------------------------------------------------------------------------------
-- Querying
-------------------------------------------------------------------------------

-- Returns an array of all products currently placed down in current blueprint. Can define `blueprintName` to get furniture for a different blueprint
function PlotService.getPlacedFurnitureProducts(player: Player, blueprintName: string?)
    -- ERROR: Bad blueprint name
    blueprintName = blueprintName or DataService.get(player, "House.Blueprint")
    if not BlueprintConstants.Objects[blueprintName] then
        error(("Bad blueprint name %q"):format(blueprintName))
    end

    local dataAddress = ("House.Furniture.%s"):format(blueprintName)
    local furniture = DataService.get(player, dataAddress)

    local productsDict: { [Products.Product]: true } = {} -- Can have multiple of the same product placd; used dictionary
    for _, furnitureMetadata: FurnitureMetadata in pairs(furniture) do
        local furnitureName = furnitureMetadata.Name
        local product = ProductUtil.getHouseObjectProduct("Furniture", furnitureName)
        productsDict[product] = true
    end

    return TableUtil.getKeys(productsDict) :: { Products.Product }
end

-- Returns product for currently used blueprint
function PlotService.getBlueprintProduct(player: Player)
    -- ERROR: No name?
    local blueprintName = DataService.get(player, "House.Blueprint")
    if not blueprintName then
        error("No blueprint name?")
    end

    return ProductUtil.getHouseObjectProduct("Blueprint", blueprintName)
end

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

local function isPositionInBoundsOfPlayersPlot(player: Player, position: Vector3): boolean
    local plot = getPlot(player, HousingConstants.InteriorType)

    local Floor = plot:FindFirstChildOfClass("Model")
    if Floor then
        Floor = Floor.Floor
    end
    local houseCFrame = CFrame.new(plot.Origin.Position)

    position = (houseCFrame * CFrame.new(position)).Position

    local boundsMin = Floor.Position - Vector3.new((Floor.Size.X / 2 + 10), 15, (Floor.Size.Z / 2) + 10)
    local boundsMax = Floor.Position + Vector3.new((Floor.Size.X / 2 + 10), 300, (Floor.Size.Z / 2) + 10)

    return (position.X >= boundsMin.X and position.X <= boundsMax.X)
        and (position.Y >= boundsMin.Y and position.Y <= boundsMax.Y)
        and (position.Z >= boundsMin.Z and position.Z <= boundsMax.Z)
end

-------------------------------------------------------------------------------
-- INTERIOR OBJECTS METHODS
-------------------------------------------------------------------------------

local function placeFurniture(player, object: Model, metadata: FurnitureMetadata): boolean
    local plot = getPlot(player, HousingConstants.InteriorType)

    local houseCFrame = CFrame.new(plot.Origin.Position)

    local position = metadata.Position -- Local, relative to house cframe
    local rotation = metadata.Rotation
    local colors = metadata.Color
    local normal = metadata.Normal

    local modelData = FurnitureConstants.Objects[metadata.Name]

    local cf = houseCFrame
        * HousingUtil.calculateObjectCFrame(
            CFrame.new(position) * CFrame.Angles(0, rotation.Y, 0) * CFrame.new(0, object:GetExtentsSize().Y / 2, 0),
            position,
            normal
        )

    if table.find(modelData.Tags, FurnitureConstants.Tags.Wall) then
        if normal == Vector3.new(0, 1, 0) then
            cf = cf * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, object:GetExtentsSize().Y / 2, 0)
        end
    end
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
local function loadHouse(player: Player, plot: Model, type: string, firstLoad: boolean?)
    plot:SetAttribute(HousingConstants.PlotOwner, player.UserId)
    plots[type][player] = plot

    local blueprint = DataService.get(player, "House.Blueprint")

    local model = assets[type .. "s"]:FindFirstChild(blueprint):Clone()
    model:PivotTo(plot.Origin.CFrame)
    model.Parent = plot

    --Sets the location as an attribute to easily be retrieved by Clients
    player:SetAttribute(type, model.Spawn.Position)

    if type == HousingConstants.InteriorType then
        if not firstLoad then --blueprint swapped
            local exitPart = plot:FindFirstChildOfClass("Model").Exit
            exitPart.Name = ZoneConstants.ZoneType.Room.Neighborhood
            exitPart.Parent = ZoneUtil.getZoneInstances(ZoneUtil.houseInteriorZone(player)).RoomDepartures

            newSpawnTable[player](plot:FindFirstChildOfClass("Model").Spawn)
        end

        -- Load objects in the house
        local address = "House.Furniture." .. blueprint
        for id, store in pairs(DataService.get(player, address)) do
            local name = store.Name
            local objectTemplate = assets.Furniture:FindFirstChild(name)

            -- Unequip any deprecated/removed items
            local productId = ProductUtil.getHouseObjectProductId("Furniture", name)
            local success = pcall(ProductUtil.getProduct, ProductConstants.ProductType.HouseObject, productId)
            if not success then
                warn(("unequipped %s furniture from %s's %s home"):format(name, player.Name, blueprint))
                DataService.set(player, ("%s.%s"):format(address, id), nil)
                continue
            end

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

        CollectionService:AddTag(plot.Mailbox, "Plot")
        CollectionService:AddTag(plot.Mailbox, "House")
        CollectionService:AddTag(plot.Mailbox, tostring(player.UserId))

        local newLabel = assets.PlayerName:Clone()

        newLabel.PlayerLabel.Text = StringUtil.possessiveName(player.DisplayName) .. " House"
        newLabel.Parent = plot.Mailbox
    end
end

-- Unloads  a house interior or exterior
local function unloadHouse(player: Player, plot: Model, type: string, oldBlueprint: string?)
    -- RETURN: Nothing to unload
    if not plot then
        return
    end

    -- HousingConstants.InteriorType is handled by the ZoneService
    if type == HousingConstants.ExteriorType then
        plot:SetAttribute(HousingConstants.PlotOwner, nil)
        if oldBlueprint and plot:FindFirstChild(oldBlueprint) then
            plot:FindFirstChild(oldBlueprint):Destroy()
        end
        CollectionService:RemoveTag(plot.Mailbox, tostring(player.UserId))
        CollectionService:RemoveTag(plot.Mailbox, "Plot")
        CollectionService:RemoveTag(plot.Mailbox, "House")

        if plot.Mailbox:FindFirstChild("PlayerName") then
            plot.Mailbox:FindFirstChild("PlayerName"):Destroy()
        end
    else
        if plot:FindFirstChild("Furniture") then
            plot.Furniture:ClearAllChildren()
        end
        if oldBlueprint and plot:FindFirstChild(oldBlueprint) then
            plot:FindFirstChild(oldBlueprint):Destroy()
        end
        if plot.Parent.ZoneInstances.RoomDepartures:FindFirstChild("Neighborhood") then --remove exit part
            plot.Parent.ZoneInstances.RoomDepartures:FindFirstChild("Neighborhood"):Destroy()
        end
    end

    plots[type][player] = nil
end

-------------------------------------------------------------------------------
-- LOADING/ UNLOADING
-------------------------------------------------------------------------------
--Runs once per player on join
function PlotService.loadPlayer(player: Player)
    local exteriorPlot: Model = findEmptyPlot(HousingConstants.ExteriorType)
    local interiorPlot: Model = findEmptyPlot(HousingConstants.InteriorType)

    loadHouse(player, exteriorPlot, HousingConstants.ExteriorType, true)
    loadHouse(player, interiorPlot, HousingConstants.InteriorType, true)

    -- Create zone for interior
    local houseInteriorZone = ZoneUtil.houseInteriorZone(player)

    local spawnPart = interiorPlot:FindFirstChildOfClass("Model").Spawn

    local destroyFunction, _, changeSpawn = ZoneService.createZone(houseInteriorZone, { interiorPlot }, spawnPart)
    PlayerService.getPlayerMaid(player):GiveTask(destroyFunction)

    local exitPart = interiorPlot:FindFirstChildOfClass("Model").Exit
    exitPart.Name = ZoneConstants.ZoneType.Room.Neighborhood
    exitPart.Parent = ZoneUtil.getZoneInstances(houseInteriorZone).RoomDepartures

    newSpawnTable[player] = changeSpawn

    local didStartingObjects = DataService.get(player, "House.DidStartingObjects")
    if didStartingObjects == nil then
        DataService.set(player, "House.DidStartingObjects", true)
        for itemName, amount in FurnitureConstants.StartingObjects do
            local product = ProductUtil.getHouseObjectProduct("Furniture", itemName)
            ProductService.addProduct(player, product, amount)
        end
    end
end

--Handles removing models and resetting plots on leave
function PlotService.unloadPlayer(player: Player)
    local exteriorPlot: Model = getPlot(player, HousingConstants.ExteriorType)
    local interiorPlot: Model = getPlot(player, HousingConstants.InteriorType)
    local bprint = DataService.get(player, "House.Blueprint")

    unloadHouse(player, exteriorPlot, HousingConstants.ExteriorType, bprint)
    unloadHouse(player, interiorPlot, HousingConstants.InteriorType, bprint)

    newSpawnTable[player] = nil
end

-------------------------------------------------------------------------------
-- SERVER/CLIENT COMMUNICATION
-------------------------------------------------------------------------------
Remotes.bindEvents({
    PlaceHouseObject = function(player: Player, type: string, metadata: Metadata)
        local product = ProductUtil.getHouseObjectProduct("Furniture", metadata.Name)
        if not ProductService.canPlaceHouseProduct(player, product) then
            return -- doesn't have enough of the iem to place
        end

        -- RETURN: Object isn't valid
        local typeConstants = HouseObjects[type]
        if not typeConstants then
            return
        end

        -- RETURN: Object isn't valid
        local name = metadata.Name
        local objectConstants = typeConstants.Objects[name]
        if not objectConstants then
            return
        end

        -- Handlers
        local blueprint = DataService.get(player, "House.Blueprint")
        if type == "Furniture" then
            local withinBounds = isPositionInBoundsOfPlayersPlot(player, metadata.Position)
            if withinBounds then
                local id = DataService.getAppendageKey(player, "House.Furniture." .. blueprint)
                local object = assets[type]:FindFirstChild(name):Clone()

                object.Name = id
                ProductService.addProduct(player, product, -1)
                local store = updateFurniture(player, object, metadata)
                if store then
                    DataService.set(player, "House.Furniture." .. blueprint .. "." .. id, store, "OnFurniturePlaced", { Id = id })
                    PlotService.ObjectPlaced:Fire(player, product, TableUtil.deepClone(metadata))
                end
            end
        end
    end,

    -- Furniture
    RemoveFurniture = function(player: Player, id: string)
        local plot = getPlot(player, HousingConstants.InteriorType)
        local blueprint = DataService.get(player, "House.Blueprint")
        local store = DataService.get(player, "House.Furniture." .. blueprint)

        -- RETURN: ITEM DOES NOT EXIST
        local metadata = store[id] and TableUtil.deepClone(store[id])
        if not metadata then
            return
        end

        local product = ProductUtil.getHouseObjectProduct("Furniture", metadata.Name)
        ProductService.addProduct(player, product, 1)
        plot.Furniture[id]:Destroy()

        DataService.set(player, "House.Furniture." .. blueprint .. "." .. id, nil, "OnFurnitureRemoved", {
            Id = id,
        })
        PlotService.ObjectRemoved:Fire(player, product, metadata)
    end,
    UpdateFurniture = function(player: Player, id: string, metadata: FurnitureMetadata)
        local plot = getPlot(player, HousingConstants.InteriorType)
        local blueprint = DataService.get(player, "House.Blueprint")
        local store = DataService.get(player, "House.Furniture." .. blueprint)

        -- RETURN: Object does not exist
        if store[id] and store[id].Name == metadata.Name then
            local lastData = store[id]
            local withinBounds = isPositionInBoundsOfPlayersPlot(player, metadata.Position)
            if withinBounds then
                local object = plot.Furniture[id]

                local newStore = updateFurniture(player, object, metadata) -- Flag for valid placement
                if newStore then
                    DataService.set(player, "House.Furniture." .. blueprint .. "." .. id, newStore, "OnFurnitureUpdated", { Id = id })

                    local product = ProductUtil.getHouseObjectProduct("Furniture", metadata.Name)
                    PlotService.ObjectUpdated:Fire(
                        player,
                        product,
                        lastData and TableUtil.deepClone(lastData),
                        newStore and TableUtil.deepClone(newStore)
                    )
                end
            end
        end
    end,

    -- Blueprint
    ChangeBlueprint = function(player: Player, name: string)
        local current = DataService.get(player, "House.Blueprint")

        if current == name then
            return --don't change if same
        end

        local product = ProductUtil.getProduct("HouseObject", ProductUtil.getBlueprintProductId("Blueprint", name))
        if not (ProductService.hasProduct(player, product) or ProductUtil.isFree(product)) then
            return --doesn't own
        end

        local interiorPlot = getPlot(player, HousingConstants.InteriorType)
        local exteriorPlot = getPlot(player, HousingConstants.ExteriorType)

        local blueprintInfo = HouseObjects.Blueprint.Objects[name]
        if blueprintInfo then
            unloadHouse(player, exteriorPlot, HousingConstants.ExteriorType, current)
            unloadHouse(player, interiorPlot, HousingConstants.InteriorType, current)

            DataService.set(player, "House.Blueprint", name, "HouseBlueprintUpdated")

            --[[local objectsPlaced = DataService.get(player, "House.Furniture")

            for _id, data in objectsPlaced do
                local objectProduct = ProductUtil.getHouseObjectProduct("Furniture", data.Name)
                ProductService.addProduct(player, objectProduct, 1)
            end]]
            if DataService.get(player, "House.Furniture." .. name) == nil then
                DataService.set(player, "House.Furniture." .. name, {})
            end

            loadHouse(player, exteriorPlot, HousingConstants.ExteriorType)
            loadHouse(player, interiorPlot, HousingConstants.InteriorType)

            local oldProduct = current and ProductUtil.getProduct("HouseObject", ProductUtil.getBlueprintProductId("Blueprint", current))
            PlotService.BlueprintChanged:Fire(player, product, oldProduct)
        end
    end,

    ChangePlot = function(player: Player, plot: Model)
        if plot:GetAttribute(HousingConstants.PlotOwner) then
            return
        end
        local exteriorPlot: Model = getPlot(player, HousingConstants.ExteriorType)

        unloadHouse(player, exteriorPlot, HousingConstants.ExteriorType, DataService.get(player, "House.Blueprint"))
        loadHouse(player, plot, HousingConstants.ExteriorType)
    end,
})

return PlotService
