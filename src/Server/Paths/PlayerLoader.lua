-- Just a nice way to load an unload everything regarding a player in one place

local Players = game:GetService("Players")

local Paths = require(script.Parent)
local modules = Paths.Modules

local PlayerLoader = {}

Players.PlayerAdded:Connect(function(player)
    modules["PlayerData"].loadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    modules["PlayerData"].unloadPlayer(player)
end)

return PlayerLoader