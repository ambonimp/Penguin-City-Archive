--Gives a player a housing plot when they rejoin, and empties it when they leave. Handles all housing server/client communication with plots and furniutre
local PlotService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(ServerScriptService.Paths)
local ObjectModule: typeof(require(Paths.Shared.HousingObjectData))
local PlayerData: typeof(require(Paths.Server.DataService))
local Limiter: typeof(require(Paths.Shared.Limiter))
local Remotes: typeof(require(Paths.Shared.Remotes))
local ZoneService: typeof(require(Paths.Server.Zones.ZoneService))
local ZoneConstants: typeof(require(Paths.Shared.Zones.ZoneConstants))
local ZoneUtil: typeof(require(Paths.Shared.Zones.ZoneUtil))

PlotService.PlayerPlot = {}
PlotService.PlayerHouse = {}

local startZone: ZoneConstants.Zone
local houseZone: ZoneConstants.Zone
local DEBOUNCE_SCOPE = "PlayerTeleport"
local DEBOUNCE_MOUNT = {
    Key = "Teleport",
    Timeframe = 0.5,
}

local assets: Folder
local folders: { Plot: Instance, House: Instance }

function PlotService.Init()
    assets = ReplicatedStorage:WaitForChild("Assets")
    folders = {
        ["Plot"] = workspace.Rooms.Neighborhood:WaitForChild("HousingPlots"),
        ["House"] = workspace.Rooms.Start:WaitForChild("Houses"),
    }
    ObjectModule = require(Paths.Shared.HousingObjectData)
    PlayerData = require(Paths.Server.Data.DataService)
    Limiter = require(Paths.Shared.Limiter)
    Remotes = require(Paths.Shared.Remotes)
    ZoneService = require(Paths.Server.Zones.ZoneService)
    ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
    ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
    houseZone = ZoneUtil.zone("Room", "Neighborhood")
    startZone = ZoneUtil.zone("Room", "Start")
    Remotes.declareEvent("EnteredHouse")
    Remotes.declareEvent("ExitedHouse")
    Remotes.declareEvent("PlotChanged")
    Remotes.declareEvent("UpdateHouseUI")
end

local function findInPlacements(id: number, placements)
    for _, data in placements do
        if data.Id == id then
            return true
        end
    end
    return false
end

local function getEmptyId(placements: { any })
    for i = 1, 1000 do
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

function setModelColor(object: Model, color: Color3)
    for _, part: BasePart in object:GetDescendants() do
        if part:IsA("BasePart") and part.Parent.Name == "CanColor" then
            part.Color = color
        end
    end
end

--Finds an empty plot for exterior/interior
local function findEmpty(folder: Folder)
    local plotMoel: Model
    for _, model: Model in folder:GetChildren() do
        if model:GetAttribute("Owner") == nil then
            plotMoel = model
            break
        end
    end
    return plotMoel
end

--Handles unloading a house interior or exterior : type; "House" for interior, "Plot" for exterior
local function unloadPlot(player: Player, plot: Model, type: string)
    --checks for given plot, if player house plot of type, or if it's in the plots table
    local plotModel: Model = plot or PlotService.doesPlayerHavePlot(player, type) or PlotService["Player" .. type][player.Name]

    if plotModel then
        if plotModel:GetAttribute("Owner") then
            plotModel:SetAttribute("Owner", nil)
        end

        if plotModel:FindFirstChildOfClass("Model") then
            plotModel:FindFirstChildOfClass("Model"):Destroy()
        end

        if plotModel:FindFirstChild("Furniture") then
            plotModel.Furniture:ClearAllChildren()
        end
    end

    PlotService["Player" .. type][player.Name] = nil
end

--Loads objects in players house
local function loadHouseInterior(player: Player, plot: Model, Model: Model)
    local houseCFrame = CFrame.new(plot.Plot.Position)
    player:SetAttribute("HouseSpawn", Model.Spawn.Position)
    local furniture = PlayerData.get(player, "Igloo.Placements")
    if furniture then
        for _, objectData in furniture do
            local itemName = objectData.Name
            local Object = assets.Housing[ObjectModule[itemName].type]:FindFirstChild(itemName)

            if Object then
                Object = Object:Clone()
                Object:PivotTo(
                    houseCFrame
                        * CFrame.new(objectData.Position[1], objectData.Position[2], objectData.Position[3])
                        * CFrame.Angles(0, math.rad(objectData.Rotation[2]), 0)
                )
                Object:SetAttribute("Id", objectData.Id)
                setModelColor(Object, Color3.fromRGB(objectData.Color[1], objectData.Color[2], objectData.Color[3]))
                Object.Parent = plot.Furniture
            end
        end
    else
        PlayerData.set(player, "Igloo.Placements", {})
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
        plot:SetAttribute("Owner", player.UserId)
        PlotService["Player" .. type][player.Name] = plot

        --load interior and exterior model of houses on server, furniture is loaded on client
        local data = PlayerData.get(player, "Igloo.Igloo" .. type)
        local Model = assets.Housing[type]:FindFirstChild(data)
        if Model then
            Model = Model:Clone()
            Model:PivotTo(plot.Plot.CFrame)
            Model.Parent = plot

            player:SetAttribute(type, Model.Spawn.Position) --Sets the location as an attribute to easily be retrieved by Clients

            --Handle entering and exiting houses
            if type == "House" then
                loadHouseInterior(player, plot, Model)
                Model.Exit.Touched:Connect(function(part: BasePart)
                    local isFree = Limiter.debounce(DEBOUNCE_SCOPE, DEBOUNCE_MOUNT.Key .. part.Parent.Name, DEBOUNCE_MOUNT.Timeframe)
                    if not isFree then
                        return
                    end
                    if game.Players:GetPlayerFromCharacter(part.Parent) then
                        local newPlayer = game.Players:GetPlayerFromCharacter(part.Parent)
                        ZoneService.teleportPlayerToZone(newPlayer, houseZone, 0, player)
                        Remotes.fireClient(newPlayer, "ExitedHouse", newPlayer)
                    end
                end)
            elseif type == "Plot" then
                Model.Entrance.Touched:Connect(function(part: BasePart)
                    local isFree = Limiter.debounce(DEBOUNCE_SCOPE, DEBOUNCE_MOUNT.Key .. part.Parent.Name, DEBOUNCE_MOUNT.Timeframe)
                    if not isFree then
                        return
                    end
                    if game.Players:GetPlayerFromCharacter(part.Parent) then
                        local newPlayer = game.Players:GetPlayerFromCharacter(part.Parent)
                        ZoneService.teleportPlayerToZone(newPlayer, startZone, 0, player)
                        Remotes.fireClient(newPlayer, "EnteredHouse", newPlayer, newPlayer == player)
                    end
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
            for _, plot: Model in folders[type]:GetChildren() do
                if plot.Plot.Position == player:GetAttribute("Plot") then
                    plotModel = plot
                    break
                end
            end
        end
    end
    return plotModel
end

--Runs once per player on join
function PlotService.loadPlayer(player: Player)
    if PlotService.doesPlayerHavePlot(player, "Plot") then
        return
    end
    local loaded = false
    local emptyPlot: Model = findEmpty(folders["Plot"])
    local emptyHouse: Model = findEmpty(folders["House"])
    if emptyPlot and emptyHouse then
        loaded = loadPlot(player, emptyPlot, "Plot")
        if loaded then
            loaded = loadPlot(player, emptyHouse, "House")
        end
    end
    if not loaded then
        unloadPlot(player, emptyPlot, "Plot")
        unloadPlot(player, emptyHouse, "House")
        player:Kick("There was an issue loading your data, please rejoin.")
    end
end

--Handles removing models and resetting plots on leave
function PlotService.unloadPlayer(player: Player)
    local plot: Model = PlotService.doesPlayerHavePlot(player, "Plot")
    local house: Model = PlotService.doesPlayerHavePlot(player, "House")
    unloadPlot(player, plot, "Plot")
    unloadPlot(player, house, "House")
end

--change the location of a players plot
--todo: add prices and price checks on server/client
function PlotService.changePlotModel(player: Player, name: string)
    local plot = PlotService.doesPlayerHavePlot(player, "Plot")
    if assets.Housing.Plot:FindFirstChild(name) then
        plot:FindFirstChildOfClass("Model"):Destroy()
        PlayerData.set(player, "Igloo.IglooPlot", name)
        loadPlot(player, plot, "Plot", true)
    end
end

--change the location of a players plot
--todo: add gamepass where you can place your house in plots outside of neighborhood
function PlotService.changePlot(player: Player, newPlot: Model)
    if newPlot:GetAttribute("Owner") == nil and newPlot.Parent == workspace.Rooms.Neighborhood.HousingPlots then
        unloadPlot(player, PlotService.doesPlayerHavePlot(player, "Plot"), "Plot")
        loadPlot(player, newPlot, "Plot")
        Remotes.fireClient(player, "PlotChanged", PlotService.doesPlayerHavePlot(player, "Plot"))
    end
end

--Change an existing objects' position, color, or rotation
function PlotService.changeObject(player: Player, id: number, position: CFrame, rotation: Vector3, color: Color3, object: Model)
    local plot = PlotService.doesPlayerHavePlot(player, "House")
    local items = PlayerData.get(player, "Igloo.Placements")
    local houseCFrame = CFrame.new(plot.Plot.Position)
    if (object and object:IsDescendantOf(plot)) and (houseCFrame.Position - position.Position).magnitude < 150 then --todo: swap to InBounds method
        local realPosition = houseCFrame:ToObjectSpace(position)
        realPosition = CFrame.new(realPosition.Position)

        object:PivotTo(houseCFrame * realPosition * CFrame.Angles(0, math.rad(rotation.Y), 0))
        setModelColor(object, color)

        for _, itemData in items do
            if itemData.Id == id then
                itemData.Position = { realPosition.X, realPosition.Y, realPosition.Z }
                itemData.Rotation = { rotation.X, rotation.Y, rotation.Z }
                itemData.Color = { color.R * 255, color.G * 255, color.B * 255 }
                break
            end
        end

        Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", items)
    end
end

--remove an object from players house
function PlotService.removeObject(player: Player, id: number, type: string)
    local plot = PlotService.doesPlayerHavePlot(player, "House")
    local items = PlayerData.get(player, "Igloo.Placements")
    local name = nil
    for _, object: Model in plot.Furniture:GetChildren() do
        if object:GetAttribute("Id") == id then
            name = object.Name
            object:Destroy()
        end
    end

    for num, data in items do
        if data.Id == id then
            PlayerData.set(player, "Igloo.Placements." .. tostring(num), nil)
            if PlayerData.get(player, "Igloo.Placements") == nil then
                PlayerData.set(player, "Igloo.Placements", {})
            end

            break
        end
    end

    if name then
        if PlayerData.get(player, "Igloo.OwnedItems." .. name) then
            PlayerData.increment(player, "Igloo.OwnedItems." .. name, 1)
        else
            PlayerData.set(player, "Igloo.OwnedItems." .. name, 1)
        end
        Remotes.fireClient(player, "UpdateHouseUI", name, PlayerData.get(player, "Igloo.OwnedItems." .. name), type)
    end

    Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", PlayerData.get(player, "Igloo.Placements"))
end

--add an object to the players house
--todo: add buying objects you have 0 of
function PlotService.newObject(player: Player, name: string, type: string, position: CFrame, rotation: Vector3, color: Color3)
    local plot = PlotService.doesPlayerHavePlot(player, "House")
    local items = PlayerData.get(player, "Igloo.Placements")
    local owned = PlayerData.get(player, "Igloo.OwnedItems")
    local houseCFrame = CFrame.new(plot.Plot.Position)
    if
        (houseCFrame.Position - position.Position).magnitude < 150 --todo: swap to InBounds method
        and (assets.Housing:FindFirstChild(type) and assets.Housing:FindFirstChild(type):FindFirstChild(name))
        and (owned[name] and owned[name] > 0)
    then
        local object = assets.Housing[type]:FindFirstChild(name):Clone()
        local realPosition = houseCFrame:ToObjectSpace(position)
        realPosition = CFrame.new(realPosition.Position)

        setModelColor(object, color)

        local itemData = {}
        itemData.Id = getEmptyId(items)
        itemData.Name = name
        itemData.Position = { realPosition.X, realPosition.Y, realPosition.Z }
        itemData.Rotation = { rotation.X, rotation.Y, rotation.Z }
        itemData.Color = { color.R * 255, color.G * 255, color.B * 255 }

        object:SetAttribute("Id", itemData.Id)
        object:PivotTo(houseCFrame * realPosition * CFrame.Angles(0, math.rad(rotation.Y), 0))
        object.Parent = plot.Furniture

        PlayerData.increment(player, "Igloo.OwnedItems." .. name, -1)
        PlayerData.append(player, "Igloo.Placements", itemData)
        Remotes.fireClient(player, "DataUpdated", "Igloo.Placements", PlayerData.get(player, "Igloo.Placements"))
        Remotes.fireClient(player, "UpdateHouseUI", name, PlayerData.get(player, "Igloo.OwnedItems." .. name), type)
    end
end

return PlotService
