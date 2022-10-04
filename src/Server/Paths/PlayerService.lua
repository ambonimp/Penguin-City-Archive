-- Just a nice way to load an unload everything regarding a player in one place
local PlayerService = {}

local Players = game:GetService("Players")
local Paths = require(script.Parent)
local DataService = require(Paths.Server.Data.DataService)
local CharacterService = require(Paths.Server.Characters.CharacterService)

local function loadPlayer(player)
    DataService.loadPlayer(player)
    CharacterService.loadPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    DataService.unloadPlayer(player)
end)

Players.PlayerAdded:Connect(loadPlayer)
for _, player in pairs(Players:GetPlayers()) do
    loadPlayer(player)
end

return PlayerService
