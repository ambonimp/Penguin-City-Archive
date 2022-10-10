local CharacterController = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Loader = require(Paths.Client.Loader)
local Maid = require(Paths.Packages.maid)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)

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
            -- Setup Collisions
            -- DescendantLooper and PropertyStack listen to instance.Destroying for proper cleanup
            DescendantLooper.add(function(descendant)
                return descendant:IsA("BasePart")
            end, function(part: BasePart)
                PropertyStack.setProperty(
                    part,
                    "CollisionGroupId",
                    PhysicsService:GetCollisionGroupId(CollisionsConstants.Groups.Characters),
                    "CharacterController",
                    -1
                )
            end, { character })

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
