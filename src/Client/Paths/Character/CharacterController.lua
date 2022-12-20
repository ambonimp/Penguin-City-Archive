local CharacterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local PropertyStack = require(Paths.Shared.PropertyStack)
local Loader = require(Paths.Client.Loader)
local Maid = require(Paths.Shared.Maid)

local Animate = Paths.Client.Character.Animate
local localPlayer = Players.LocalPlayer
local loadMaid = Maid.new()

local SPRINT_WALKSPEED = 30
local DEFAULT_WALKSPEED = 16

local isSprinting = false

local function unloadCharacter(_character: Model)
    loadMaid:Cleanup()
end

local function loadCharacter(character: Model)
    task.defer(function()
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
    end)
end

function CharacterController.SetWalkspeed(new: number, key: string)
    PropertyStack.setProperty(localPlayer.Character.Humanoid, "WalkSpeed", new, key)
end

function CharacterController.ToggleSprint()
    isSprinting = not isSprinting
    CharacterController.SetWalkspeed(isSprinting and SPRINT_WALKSPEED or DEFAULT_WALKSPEED, "sprint")
    return isSprinting
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(loadCharacter)
end)

return CharacterController
