local CharacterService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local PlayerService = require(Paths.Server.PlayerService)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local Nametag = require(Paths.Shared.Nametag)

Players.CharacterAutoLoads = false

local function setupCharacter(character: Model)
    -- Setup Collisions
    do
        -- DescendantLooper and PropertyStack listen to instance.Destroying for cache cleanup
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
    end
end

function CharacterService.loadPlayer(player: Player)
    -- Load Character
    local character = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
    character.Name = player.Name
    player.Character = character
    character.Parent = Workspace

    CharacterItemService.loadCharacter(character)

    -- Setup Humanoid
    local humanoid = character.Humanoid
    humanoid.WalkSpeed = CharacterConstants.WalkSpeed
    humanoid.JumpPower = CharacterConstants.JumpPower

    -- Character Setup
    setupCharacter(character)
    PlayerService.getPlayerMaid(player):GiveTask(player.CharacterAdded:Connect(function(newCharacter: Model)
        setupCharacter(newCharacter)
    end))

    -- Nametag
    local aestheticRoleDetails = PlayerService.getAestheticRoleDetails(player)
    local nametagText = aestheticRoleDetails and ("%s %s  "):format(aestheticRoleDetails.Emoji, player.DisplayName) or player.DisplayName

    local nametag = Nametag.new()
    nametag:Mount(character)
    nametag:HideFrom(player)
    nametag:SetName(nametagText)
    PlayerService.getPlayerMaid(player):GiveTask(nametag)
end

return CharacterService
