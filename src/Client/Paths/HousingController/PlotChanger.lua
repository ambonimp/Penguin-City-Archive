local PlotChanger = {}

local Paths = require(script.Parent.Parent)
local ObjectModule = require(Paths.Shared.HousingObjectData)
local HousingController = require(Paths.Client.HousingController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Camera = workspace.CurrentCamera
local CurrentPlot: Model | nil
local Plots = workspace.HousingPlots
local total = #Plots:GetChildren()
local current = 1

local function GetPlot()
    CurrentPlot = HousingController.GetPlayerPlot(Player, workspace.HousingPlots)
end

local function moveCameraTo(position: number)
    local plot = Plots:FindFirstChild(tostring(position))
    HousingScreen.UpdatePlotUI(plot)
    PlotChanger.SetPlot(plot)
    if plot:GetAttribute("Owner") then
        CameraUtil.lookAt(Camera, plot, Vector3.new(0, 0, 42), TweenInfo.new(0.2))
    else
        CameraUtil.lookAt(Camera, plot, Vector3.new(0, 8, 35), TweenInfo.new(0.2))
    end
    CurrentPlot = plot
end

function PlotChanger.ResetCamera()
    CameraUtil.setPlayerControl(Camera)
    Player.Character.Humanoid.WalkSpeed = 16
end

function PlotChanger.SetPlot(plot: Model?)
    if plot then
        CurrentPlot = plot
    else
        GetPlot()
    end
end

function PlotChanger.EnterPlot(plot: Model?)
    Player.Character.Humanoid.WalkSpeed = 0
    current = tonumber(plot.Name)
    moveCameraTo(current)
end

function PlotChanger.NextPlot()
    if current + 1 > total then
        current = 1
    else
        current += 1
    end
    moveCameraTo(current)
end

function PlotChanger.PreviousPlot()
    if current - 1 < 1 then
        current = total
    else
        current -= 1
    end
    moveCameraTo(current)
end

function PlotChanger:GetCurrentPlot(): Model | nil
    return CurrentPlot
end

return PlotChanger
