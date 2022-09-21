local Players = game:GetService("Players")

local Paths = require(script.Parent)
local modules = Paths.Modules

local player = Players.LocalPlayer

local function unloadCharacter()
    modules.Vehicles.unloadCharacter()
end

local function loadCharacter(char)
    if char then
        task.defer(function() -- Everything inside the character should be loaded
            modules.Vehicles.loadCharacter(char)
        end)

        local conn
        conn = char.Humanoid.Died:Connect(function()
            conn:Disconnect()
            unloadCharacter()
        end)
    end
end

loadCharacter(player.Character)
player.CharacterAdded:Connect(loadCharacter)

return {}
