--Gives a player a housing plot when they rejoin, and empties it when they leave. Handles all housing server/client communication with plots and furniutre
local PlotService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local Remotes = require(Paths.Shared.Remotes)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local DataService = require(Paths.Server.Data.DataService)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local HouseObjects = require(Paths.Shared.Constants.HouseObjects)
local PlayerService = require(Paths.Server.PlayerService)

local ID_CHECK_AMOUNT = 1000
PlotService.PlayerPlot = {} :: { [string]: Model }
PlotService.PlayerHouse = {} :: { [string]: Model }

local assets: Folder
local folders: { [string]: Instance }

function PlotService.Init()
    assets = ReplicatedStorage:WaitForChild("Assets")
    folders = {
        [HousingConstants.PlotType] = workspace.Rooms.Neighborhood:WaitForChild(HousingConstants.ExteriorFolderName),
    }
    Remotes.declareEvent("EnteredHouse")
    Remotes.declareEvent("ExitedHouse")
    Remotes.declareEvent("PlotChanged")
    Remotes.declareEvent("UpdateHouseUI")

    for _, plot in ipairs(Workspace.Rooms.Neighborhood.HousingPlots:GetChildren()) do
        InteractionUtil.createInteraction(plot.Mailbox, {
            ObjectText = "Mailbox",
            ActionText = "Open",
        })
    end
end

local function findInPlacements(id: number, placements)
    for _, data in pairs(placements) do
        if data.Id == id then
            return true
        end
    end
    return false
end

local function getEmptyId(placements: { any })
    for i = 1, ID_CHECK_AMOUNT do
        if not findInPlacements(i, placements) then
            return i
        end
    end
    return #placements + 1
end

function PlotService.Start()
    Remotes.bindEvents({
        ChangeObject = function(player: Player, id: number, position: CFrame, rotation: Vector3, color: Color3, object: Model)
            PlotService.changeObject(player, id, position, rotation, color, object)
        end,
        RemoveObject = function(player: Player, id: number, type: string)
            PlotService.removeObject(player, id, type)
        end,
        NewObject = function(player: Player, name: string, type: string, position: CFrame, rotation: Vector3, color: Color3)
            PlotService.newObject(player, name, type, position, rotation, color)
        end,
        ChangePlot = function(player: Player, newPlot: Model)
            PlotService.changePlot(player, newPlot)
        end,
        ChangePlotModel = function(player: Player, name: string)
            PlotService.changePlotModel(player, name)
        end,
    })
end

local function setModelColor(object: Model, color: Color3)
    for _, part: BasePart in pairs(object:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent.Name == "CanColor" then
            part.Color = color
        end
    end
end

--Finds an empty plot for exterior/interior
local function findEmpty(type: string)
    if type == HousingConstants.PlotType then
        local plotMoel: Model
        for _, model: Model in folders[type]:GetChildren() do
            if model:GetAttribute(HousingConstants.PlotOwner) == nil then
                plotMoel = model
                break
            end
        end
        return plotMoel
    elseif type == HousingConstants.HouseType then
        local interiorModel = assets.Housing.InteriorPlot:Clone()
        return interiorModel
    else
        warn(("Unknown house type %q"):format(type))
    end
end

--Handles unloading a house interior or exterior : type; HousingConstants.HouseType for interior, HousingConstants.PlotType for exterior
local function unloadPlot(player: Player, plot: Model, type: string)
    -- HousingConstants.HouseType is handled by the ZoneService
    if type == HousingConstants.PlotType then
        --checks for given plot, if player house plot of type, or if it's in the plots table
        local plotModel: Model = plot or PlotService.doesPlayerHavePlot(player, type) or PlotService["Player" .. type][player.Name]

        if plotModel then
            if plotModel:GetAttribute(HousingConstants.PlotOwner) then
                plotModel:SetAttribute(HousingConstants.PlotOwner, nil)
            end

            if plotModel:FindFirstChildOfClass("Model") then
                plotModel:FindFirstChildOfClass("Model"):Destroy()
            end

            if plotModel:FindFirstChild("Furniture") then
                plotModel.Furniture:ClearAllChildren()
            end
        end
    end

    PlotService["Player" .. type][player.Name] = nil
end

--Loads objects in players house
local function loadHouseInterior(player: Player, plot: Model)
    local houseCFrame = CFrame.new(plot.Plot.Position)

    local furniture = DataService.get(player, "Igloo.Placements")
    for _, objectData in pairs(furniture) do
        local itemName = objectData.Name
        local Object = assets.Housing.Furniture:FindFirstChild(itemName)

        print(DataUtil.desieralizeValue(objectData.Position, Vector3))
        print(DataUtil.desieralizeValue(objectData.Rotation, Vector3))
        print(DataUtil.desieralizeValue(objectData.Color, Color3))

        if Object then
            Object = Object:Clone()
            Object:PivotTo(
                houseCFrame
                    * CFrame.new(DataUtil.desieralizeValue(objectData.Position, Vector3))
                    * CFrame.Angles(0, math.rad(DataUtil.desieralizeValue(objectData.Rotation, Vector3).Y), 0)
            )

            Object:SetAttribute("Id", objectData.Id)
            setModelColor(Object, DataUtil.desieralizeValue(objectData.Color, Color3))
            Object.Parent = plot.Furniture
        end
    end
end

--Loads a house interior or exterior
local function loadPlot(player: Player, plot: Model, type: string, isChange: boolean?)
    local PlayerPlot: Model = PlotService.doesPlayerHavePlot(player, type)
    if PlayerPlot ~= plot and PlayerPlot ~= nil and not isChange then
        unloadPlot(player, PlayerPlot, type)
    elseif PlayerPlot == plot and not isChange then
        return false
    else
        plot:SetAttribute(HousingConstants.PlotOwner, player.UserId)
        PlotService["Player" .. type][player.Name] = plot

        --load interior and exterior model of houses on server, furniture is loaded on client
        local data = DataService.get(player, "Igloo.Igloo" .. type)
        local Model = assets.Housing[type]:FindFirstChild(data)
        if Model then
            Model = Model:Clone()
            Model:PivotTo(plot.Plot.CFrame)
            Model.Parent = plot

            player:SetAttribute(type, Model.Spawn.Position) --Sets the location as an attribute to easily be retrieved by Clients

            --Handle entering and exiting houses
            if type == HousingConstants.HouseType then
                loadHouseInterior(player, plot)
            elseif type == HousingConstants.PlotType then
                local zone = ZoneUtil.houseZone(player)

                -- Departure
                local entrancePart: BasePart = Model.Entrance
                entrancePart.Name = zone.ZoneId
                entrancePart.Parent = game.Workspace.Rooms.Neighborhood.ZoneInstances.RoomDepartures

                -- Arrival
                local spawnPart = Model.Spawn
                spawnPart.Name = zone.ZoneId
                spawnPart.Parent = game.Workspace.Rooms.Neighborhood.ZoneInstances.RoomArrivals

                -- Cleanup
                Model.Destroying:Connect(function()
                    entrancePart:Destroy()
                    spawnPart:Destroy()
                end)
            end
        end

        return true
    end
end

--Returns a players plot model
function PlotService.doesPlayerHavePlot(player: Player, type: string): Model | nil
    local plotModel: Model
    if player:GetAttribute(type) then
        if PlotService["Player" .. type][player.Name] then
            plotModel = PlotService["Player" .. type][player.Name]
        end
        if not plotModel then
            if type == HousingConstants.PlotType then
                for _, plot: Model in folders[type]:GetChildren() do
                    if plot.Plot.Position == player:GetAttribute(HousingConstants.PlotType) then
                        plotModel = plot
                        break
                    end
                end
            elseif type == HousingConstants.HouseType then
                return game.Workspace.Rooms:FindFirstChild(ZoneUtil.houseZone(player).ZoneId)
            else
                warn(("Unknown house type %q"):format(type))
            end
        end
    end
    return plotModel
end

--Runs once per player on join
function PlotService.loadPlayer(player: Player)
    if PlotService.doesPlayerHavePlot(player, HousingConstants.PlotType) then
        return
    end

    local loaded = false
    local emptyPlot: Model = findEmpty(HousingConstants.PlotType)
    local emptyHouse: Model = findEmpty(HousingConstants.HouseType)
    if emptyPlot and emptyHouse then
        loaded = loadPlot(player, emptyPlot, HousingConstants.PlotType)
        if loaded then
            loaded = loadPlot(player, emptyHouse, HousingConstants.HouseType)
        end
    end

    if not loaded then
        unloadPlot(player, emptyPlot, HousingConstants.PlotType)
        unloadPlot(player, emptyHouse, HousingConstants.HouseType)
        player:Kick("There was an issue loading your data, please rejoin.")
        return
    end

    -- Loaded

    -- create zone for interior
    local houseZone = ZoneUtil.houseZone(player)

    local spawnPart = emptyHouse:FindFirstChildOfClass("Model").Spawn
    local destroyFunction = ZoneService.createZone(houseZone.ZoneType, houseZone.ZoneId, { emptyHouse }, spawnPart)
    PlayerService.getPlayerMaid(player):GiveTask(destroyFunction)

    local exitPart = emptyHouse:FindFirstChildOfClass("Model").Exit
    exitPart.Name = ZoneConstants.ZoneId.Room.Neighborhood
    exitPart.Parent = ZoneUtil.getZoneInstances(houseZone).RoomDepartures
end

--Handles removing models and resetting plots on leave
function PlotService.unloadPlayer(player: Player)
    local plot: Model = PlotService.doesPlayerHavePlot(player, HousingConstants.PlotType)
    local house: Model = PlotService.doesPlayerHavePlot(player, HousingConstants.HouseType)
    unloadPlot(player, plot, HousingConstants.PlotType)
    unloadPlot(player, house, HousingConstants.HouseType)
end

--change the location of a players plot
--todo: add prices and price checks on server/client
function PlotService.changePlotModel(player: Player, name: string)
    local plot = PlotService.doesPlayerHavePlot(player, HousingConstants.PlotType)
    if assets.Housing.Plot:FindFirstChild(name) then
        plot:FindFirstChildOfClass("Model"):Destroy()
        DataService.set(player, "Igloo.IglooPlot", name)
        loadPlot(player, plot, HousingConstants.PlotType, true)
    end
end

--change the location of a players plot
--todo: add gamepass where you can place your house in plots outside of neighborhood
function PlotService.changePlot(player: Player, newPlot: Model)
    if newPlot:GetAttribute(HousingConstants.PlotOwner) == nil and newPlot.Parent == workspace.Rooms.Neighborhood.HousingPlots then
        unloadPlot(player, PlotService.doesPlayerHavePlot(player, HousingConstants.PlotType), HousingConstants.PlotType)
        loadPlot(player, newPlot, HousingConstants.PlotType)
        Remotes.fireClient(player, "PlotChanged", PlotService.doesPlayerHavePlot(player, HousingConstants.PlotType))
    end
end

--Change an existing objects' position, color, or rotation
function PlotService.changeObject(player: Player, id: number, position: CFrame, rotation: Vector3, color: Color3, object: Model)
    local plot = PlotService.doesPlayerHavePlot(player, HousingConstants.HouseType)
    local items = DataService.get(player, "Igloo.Placements")
    local houseCFrame = CFrame.new(plot.Plot.Position)
    if (object and object:IsDescendantOf(plot)) and (houseCFrame.Position - position.Position).magnitude < 150 then --todo: swap to InBounds method
        local realPosition = houseCFrame:ToObjectSpace(position)
        realPosition = CFrame.new(realPosition.Position)

        object:PivotTo(houseCFrame * realPosition * CFrame.Angles(0, math.rad(rotation.Y), 0))
        setModelColor(object, color)

        for _, itemData in pairs(items) do
            if itemData.Id == id then
                itemData.Position = DataUtil.serializeValue(realPosition)
                itemData.Rotation = DataUtil.serializeValue(rotation)
                itemData.Color = DataUtil.serializeValue(color)
                break
            end
        end

        Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", items)
    end
end

--remove an object from players house
function PlotService.removeObject(player: Player, id: number, type: string)
    local plot = PlotService.doesPlayerHavePlot(player, HousingConstants.HouseType)
    local items = DataService.get(player, "Igloo.Placements")
    local name = nil
    for _, object: Model in pairs(plot.Furniture:GetChildren()) do
        if object:GetAttribute(HousingConstants.ModelId) == id then
            name = object.Name
            object:Destroy()
        end
    end

    for num, data in pairs(items) do
        if data.Id == id then
            DataService.set(player, "Igloo.Placements." .. tostring(num), nil)
            if DataService.get(player, "Igloo.Placements") == nil then
                DataService.set(player, "Igloo.Placements", {})
            end

            break
        end
    end

    if name then
        if DataService.get(player, "Igloo.OwnedItems." .. name) then
            DataService.increment(player, "Igloo.OwnedItems." .. name, 1)
        else
            DataService.set(player, "Igloo.OwnedItems." .. name, 1)
        end
        Remotes.fireClient(player, "UpdateHouseUI", name, DataService.get(player, "Igloo.OwnedItems." .. name), type)
    end

    Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", DataService.get(player, "Igloo.Placements"))
end

--add an object to the players house
--todo: add buying objects you have 0 of
function PlotService.newObject(player: Player, name: string, type: string, position: CFrame, rotation: Vector3, color: Color3)
    -- RETURN: Object does not exist
    if not HouseObjects.Furniture.Objects[name] then
        return
    end

    local plot = PlotService.doesPlayerHavePlot(player, HousingConstants.HouseType)
    local items = DataService.get(player, "Igloo.Placements")
    local owned = DataService.get(player, "Igloo.OwnedItems")
    local houseCFrame = CFrame.new(plot.Plot.Position)

    if
        (houseCFrame.Position - position.Position).Magnitude < 150 --todo: swap to InBounds method
        and (assets.Housing:FindFirstChild(type) and assets.Housing:FindFirstChild(type):FindFirstChild(name))
        and (owned[name] and owned[name] :: number > 0)
    then
        local object = assets.Housing[type]:FindFirstChild(name):Clone()
        local realPosition = houseCFrame:ToObjectSpace(position)
        realPosition = CFrame.new(realPosition.Position)

        setModelColor(object, color)

        local itemData = {}
        itemData.Id = getEmptyId(items)
        itemData.Name = name
        itemData.Position = DataUtil.serializeValue(realPosition)
        itemData.Rotation = DataUtil.serializeValue(rotation)
        itemData.Color = DataUtil.serializeValue(color)

        object:SetAttribute("Id", itemData.Id)
        object:PivotTo(houseCFrame * realPosition * CFrame.Angles(0, math.rad(rotation.Y), 0))
        object.Parent = plot.Furniture

        DataService.increment(player, "Igloo.OwnedItems." .. name, -1)
        DataService.set(player, "Igloo.Placements." .. itemData.Id, itemData)
        Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", DataService.get(player, "Igloo.Placements"))
        Remotes.fireClient(player, "UpdateHouseUI", name, DataService.get(player, "Igloo.OwnedItems." .. name), type)
    end
end

return PlotService
