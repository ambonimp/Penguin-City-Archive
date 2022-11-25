local CharacterService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local DataService = require(Paths.Server.Data.DataService)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local PlayerService = require(Paths.Server.PlayerService)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local Nametag = require(Paths.Shared.Nametag)

Players.CharacterAutoLoads = false

-- Moves a character so that they're standing above a part, usefull for spawning
function CharacterService.standOn(character: Model, platform: BasePart, useRandomPosition: boolean?)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    character.WorldPivot = humanoidRootPart.CFrame

    local pivotCFrame: CFrame
    if useRandomPosition then
        pivotCFrame = platform.CFrame:ToWorldSpace(
            CFrame.new(
                MathUtil.nextNumber(-platform.Size.X / 2, platform.Size.X / 2),
                character.Humanoid.HipHeight + (platform.Size + humanoidRootPart.Size).Y / 2,
                MathUtil.nextNumber(-platform.Size.Z / 2, platform.Size.Z / 2)
            )
        )
    else
        pivotCFrame =
            platform.CFrame:ToWorldSpace(CFrame.new(0, character.Humanoid.HipHeight + (platform.Size + humanoidRootPart.Size).Y / 2, 0))
    end
    character:PivotTo(pivotCFrame)
end

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

    -- Apply saved appearance
    CharacterUtil.applyAppearance(character, DataUtil.readAsArray(DataService.get(player, "CharacterAppearance")))

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
    local nametag = Nametag.new()
    nametag:Mount(character)
    nametag:HideFrom(player)
    nametag:SetName(player.DisplayName)
    PlayerService.getPlayerMaid(player):GiveTask(nametag)
end

return CharacterService
