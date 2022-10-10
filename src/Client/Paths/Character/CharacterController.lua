local CharacterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Loader = require(Paths.Client.Loader)
local Maid = require(Paths.Packages.maid)

local Animate = Paths.Client.Character.Animate
local localPlayer = Players.LocalPlayer
local loadMaid = Maid.new()

local function unloadCharacter(_character: Model)
    loadMaid:Cleanup()
end

local function loadCharacter(character: Model)
    loadMaid:Cleanup()

    if character then
        local animate = Animate:Clone()
        animate.Disabled = false
        animate.Parent = character

        if character then
            -- Death cleanup
            loadMaid:GiveTask(character.Humanoid.Died:Connect(function()
                unloadCharacter(character)
            end))
        end
    end
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(loadCharacter)
end)

return CharacterController
