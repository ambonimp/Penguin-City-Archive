local PlotChanger = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local HousingController = require(Paths.Client.HousingController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local currentPlot: Model | nil
local plots = workspace.Rooms.Neighborhood.HousingPlots
local total = #plots:GetChildren()
local current = 1

local function GetPlot()
    currentPlot = HousingController.getPlayerPlot(player, workspace.Rooms.Neighborhood.HousingPlots)
end

local function moveCameraTo(position: number)
    local plot = plots:FindFirstChild(tostring(position))
    HousingScreen.updatePlotUI(plot)
    PlotChanger.setPlot(plot)
    if plot:GetAttribute("Owner") then
        CameraUtil.lookAt(camera, plot, Vector3.new(0, 0, 42), TweenInfo.new(0.2))
    else
        CameraUtil.lookAt(camera, plot, Vector3.new(0, 8, 35), TweenInfo.new(0.2))
    end
    currentPlot = plot
end

function PlotChanger.resetCamera()
    CameraUtil.setPlayerControl(camera)
    player.Character.Humanoid.WalkSpeed = 16
end

function PlotChanger.setPlot(plot: Model?)
    if plot then
        currentPlot = plot
    else
        GetPlot()
    end
end

function PlotChanger.enterPlot(plot: Model?)
    player.Character.Humanoid.WalkSpeed = 0
    current = tonumber(plot.Name)
    moveCameraTo(current)
end

function PlotChanger.nextPlot()
    if current + 1 > total then
        current = 1
    else
        current += 1
    end
    moveCameraTo(current)
end

function PlotChanger.previousPlot()
    if current - 1 < 1 then
        current = total
    else
        current -= 1
    end
    moveCameraTo(current)
end

function PlotChanger:GetCurrentPlot(): Model | nil
    return currentPlot
end

return PlotChanger
