local Players = game:GetService("Players")
local Paths = require(script.Parent)
local Modules = Paths.Modules
local Vehicles = Modules.Vehicles

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

Paths.Modules.Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
end)
localPlayer.CharacterAdded:Connect(loadCharacter)

return {}
