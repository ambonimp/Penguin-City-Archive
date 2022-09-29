local CharacterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Loader = require(Paths.Client.Loader)

local Animate = Paths.Client.Character.Animate

local localPlayer = Players.LocalPlayer

function loadCharacter(character)
    if character then
        local animate = Animate:Clone()
        animate.Disabled = false
        animate.Parent = character

        if character then
            task.defer(function()
                -- Character dependencies
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
    -- Character dependencies
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(loadCharacter)
end)

return CharacterController
