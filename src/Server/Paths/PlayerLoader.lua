-- Just a nice way to load an unload everything regarding a player in one place
local PlayerLoader = {}

local Players = game:GetService("Players")
local Paths = require(script.Parent)
local PlayerData = require(Paths.Server.PlayerData)

Players.PlayerAdded:Connect(function(player)
    PlayerData.loadPlayer(player)
end)
for _, player in pairs(Players:GetPlayers()) do
    PlayerData.loadPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    PlayerData.unloadPlayer(player)
end)

return PlayerLoader
