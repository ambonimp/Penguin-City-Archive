local PlotChanger = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local HousingController = require(Paths.Client.HousingController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local CameraController = require(Paths.Client.CameraController)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)

local PLOT_OWNER_CAMERA_LOOKAT = Vector3.new(0, 0, 42)
local NO_PLOT_OWNER_CAMERA_LOOKAT = Vector3.new(0, 8, 35)
local CAMERA_TWEEN_INFO = TweenInfo.new(0.2)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local currentPlot: Model?
local plots = workspace.Rooms.Neighborhood.HousingPlots
local total = #plots:GetChildren()
local current = 1

local function getPlot()
    currentPlot = HousingController.getPlayerPlot(player, plots)
end

--position is the name of a plot
local function moveCameraTo(position: number)
    local plot = plots:FindFirstChild(tostring(position))
    HousingScreen.updatePlotUI(plot)
    PlotChanger.setPlot(plot)
    if plot:GetAttribute(HousingConstants.PlotOwner) then
        CameraUtil.lookAt(camera, plot, PLOT_OWNER_CAMERA_LOOKAT, CAMERA_TWEEN_INFO)
    else
        CameraUtil.lookAt(camera, plot, NO_PLOT_OWNER_CAMERA_LOOKAT, CAMERA_TWEEN_INFO)
    end
    currentPlot = plot
end

function PlotChanger.resetCamera()
    CameraController.setPlayerControl()
    CharacterUtil.unfreeze(player.Character)
end

function PlotChanger.setPlot(plot: Model?)
    if plot then
        currentPlot = plot
    else
        getPlot()
    end
end

function PlotChanger.enterPlot(plot: Model?)
    CharacterUtil.freeze(player.Character)
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
