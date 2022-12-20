local CharacterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local PropertyStack = require(Paths.Shared.PropertyStack)
local Loader = require(Paths.Client.Loader)
local Maid = require(Paths.Shared.Maid)
local InputController = require(Paths.Client.Input.InputController)

local Animate = Paths.Client.Character.Animate
local localPlayer = Players.LocalPlayer
local loadMaid = Maid.new()

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

function CharacterController.Start()
    InputController.KeybindBegan:Connect(function(keybind: string, gameProcessedEvent: boolean)
        -- RETURN: Not a good keybind for us!
        if not (keybind == "Sprint" and not gameProcessedEvent) then
            return
        end

        CharacterController.toggleSprint()
    end)
end

function CharacterController.setWalkspeed(new: number, key: string)
    PropertyStack.setProperty(localPlayer.Character.Humanoid, "WalkSpeed", new, key)
end

function CharacterController.toggleSprint()
    isSprinting = not isSprinting
    CharacterController.setWalkspeed(isSprinting and CharacterConstants.SprintSpeed or CharacterConstants.WalkSpeed, "sprint")
    return isSprinting
end

Loader.giveTask("Character", "LoadCharacter", function()
    loadCharacter(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(loadCharacter)
end)

return CharacterController
