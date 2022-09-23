local Camera = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)

local camera = Workspace.CurrentCamera

Camera.FOV = TweenableValue.new("IntValue", 70, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
Camera.FOV:BindToProperty(camera, "FieldOfView")

return Camera
