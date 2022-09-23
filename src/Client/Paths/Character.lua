local Character = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Modules = Paths.Modules
local Vehicles = require(Modules.Vehicles)
local Loader = require(Modules.Loader)

local localPlayer = Players.LocalPlayer

local function unloadCharacter()
    Vehicles.unloadCharacter()
end

local function loadCharacter(character: Model)
    if character then
        task.defer(function() -- Everything inside the character should be loaded
            Vehicles.loadCharacter(character)
        end)

        local conn
        conn = character.Humanoid.Died:Connect(function()
            conn:Disconnect()
            unloadCharacter()
        end)
    end
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
end)
localPlayer.CharacterAdded:Connect(loadCharacter)

return Character
