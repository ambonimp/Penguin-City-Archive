local Players = game:GetService("Players")
local Character = {}

local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Vehicles = require(Paths.Client.Vehicles)
local Loader = require(Paths.Client.Loader)

local Animate = script.Animate

local localPlayer = Players.LocalPlayer

function loadCharacter(character)
    if character then
        local animate = Animate:Clone()
        animate.Disabled = false
        animate.Parent = character

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
end

function unloadCharacter()
    Vehicles.unloadCharacter()
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(loadCharacter)
end)

return Character
