-- Just a nice way to load an unload everything regarding a player in one place
local PlayerLoader = {}

local Players = game:GetService("Players")
local Paths = require(script.Parent)
local PlayerData = require(Paths.Server.PlayerData)
local CharacterService = require(Paths.Server.CharacterService)

local function loadPlayer(player)
    PlayerData.loadPlayer(player)
    CharacterService.loadPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    PlayerData.unloadPlayer(player)
end)

Players.PlayerAdded:Connect(loadPlayer)
for _, player in pairs(Players:GetPlayers()) do
    loadPlayer(player)
end

return PlayerLoader
