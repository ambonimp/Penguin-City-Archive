--Gives a player a housing plot when they rejoin, and empties it when they leave.
local PlotLoader = {}
local Paths = require(script.Parent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectModule: typeof(require(Paths.Shared.HousingObjectData))
local PlayerData: typeof(require(Paths.Server.DataService))
local Limiter: typeof(require(Paths.Shared.Limiter))

PlotLoader.PlayerPlot = {}
PlotLoader.PlayerHouse = {}

local DEBOUNCE_SCOPE = "PlayerTeleport"
local DEBOUNCE_MOUNT = {
    Key = "Teleport",
    Timeframe = 0.25,
}

local assets: Folder
local folders

function PlotLoader.Init()
    assets = ReplicatedStorage:WaitForChild("Assets")
    folders = {
        ["Plot"] = workspace:WaitForChild("HousingPlots"),
        ["House"] = workspace:WaitForChild("Houses"),
    }
    ObjectModule = require(Paths.Shared.HousingObjectData)
    PlayerData = require(Paths.Server.DataService)
    Limiter = require(Paths.Shared.Limiter)
end

function PlotLoader.Start() end

--Finds an empty plot for exterior/interior
local function FindEmpty(folder: Folder)
    local plotMoel: Model
    for _, model in folder:GetChildren() do
        if model:GetAttribute("Owner") == nil then
            plotMoel = model
            break
        end
    end
    return plotMoel
end

--Handles unloading a house interior or exterior : type; "House" for interior, "Plot" for exterior
local function UnloadPlot(player: Player, plot: Model, type: string)
    --checks for given plot, if player house plot of type, or if it's in the plots table
    local plotModel: Model = plot or PlotLoader.PlayerHasPlot(player, type) or PlotLoader["Player" .. type][player.Name]

    if plotModel then
        if plotModel:GetAttribute("Owner") then
            plotModel:SetAttribute("Owner", nil)
        end

        if plotModel:FindFirstChildOfClass("Model") then
            plotModel:FindFirstChildOfClass("Model"):Destroy()
        end
    end

    PlotLoader["Player" .. type][player.Name] = nil
end

--Loads interactable objects in players house
local function loadHouseInterior(player: Player, plot: Model, Model: Model)
    local houseCFrame = CFrame.new(plot.Plot.Position) * CFrame.Angles(0, math.rad(180), 0)
    player:SetAttribute("HouseSpawn", Model.Spawn.Position)
    local furniture = PlayerData.get(player, "Igloo.Placements")
    for itemName, objectData in furniture do
        if ObjectModule[itemName].interactable then
            local Object = assets.Housing[ObjectModule[itemName].type]:FindFirstChild(itemName)

            if Object then
                Object = Object:Clone()
                Object:SetPrimaryPartCFrame(
                    houseCFrame
                        * CFrame.new(objectData.Position[1], objectData.Position[2], objectData.Position[3])
                        * CFrame.Angles(
                            math.rad(objectData.Rotation[1]),
                            math.rad(objectData.Rotation[2]),
                            math.rad(objectData.Rotation[3])
                        )
                )
                Object.Parent = workspace.LoadedHouse
            end
        end
    end
end
--Loads a house interior or exterior
local function LoadPlot(player: Player, plot: Model, type: string)
    local PlayerPlot: Model = PlotLoader.PlayerHasPlot(player, type)
    if PlayerPlot ~= plot and PlayerPlot ~= nil then
        UnloadPlot(player, PlayerPlot, type)
    elseif PlayerPlot == plot then
        return false
    else
        plot:SetAttribute("Owner", player.UserId)
        PlotLoader["Player" .. type][player.Name] = plot

        --load interior and exterior model of houses on server, furniture is loaded on client
        local data = PlayerData.get(player, "Igloo.Igloo" .. type)
        local Model = assets.Housing[type]:FindFirstChild(data)
        if Model then
            Model = Model:Clone()
            Model:PivotTo(plot.Plot.CFrame)
            Model.Parent = plot

            player:SetAttribute(type, Model.Spawn.Position)
            if type == "House" then
                loadHouseInterior(player, plot, Model)
                Model.Exit.Touched:Connect(function(part: BasePart)
                    local isFree = Limiter.debounce(DEBOUNCE_SCOPE, DEBOUNCE_MOUNT.Key .. part.Parent.Name, DEBOUNCE_MOUNT.Timeframe)
                    if not isFree then
                        return
                    end
                    if game.Players:GetPlayerFromCharacter(part.Parent) then
                        local newPlayer = game.Players:GetPlayerFromCharacter(part.Parent)
                        newPlayer.Character:PivotTo(CFrame.new(player:GetAttribute("Plot")))
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
                        newPlayer.Character:PivotTo(CFrame.new(player:GetAttribute("House")))
                    end
                end)
            end
        end

        return true
    end
end

--Returns a players plot model
function PlotLoader.PlayerHasPlot(player: Player, type: string)
    local plotModel: Model
    if player:GetAttribute(type) then
        if PlotLoader["Player" .. type][player.Name] then
            plotModel = PlotLoader["Player" .. type][player.Name]
        end
        if not plotModel then
            for _, plot in folders[type]:GetChildren() do
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
function PlotLoader.PlayerAdded(player: Player)
    if PlotLoader.PlayerHasPlot(player, "Plot") then
        return
    end
    local loaded = false
    local emptyPlot: Model = FindEmpty(folders["Plot"])
    local emptyHouse: Model = FindEmpty(folders["House"])
    if emptyPlot and emptyHouse then
        loaded = LoadPlot(player, emptyPlot, "Plot")
        if loaded then
            loaded = LoadPlot(player, emptyHouse, "House")
        end
    end
    if not loaded then
        UnloadPlot(player, emptyPlot, "Plot")
        UnloadPlot(player, emptyHouse, "House")
        player:Kick("There was an issue loading your data, please rejoin.")
    end
end

--Runs once per player on leave
function PlotLoader.PlayerRemoving(player: Player)
    local plot: Model = PlotLoader.PlayerHasPlot(player, "Plot")
    local house: Model = PlotLoader.PlayerHasPlot(player, "House")
    UnloadPlot(player, plot, "Plot")
    UnloadPlot(player, house, "House")
end

return PlotLoader
