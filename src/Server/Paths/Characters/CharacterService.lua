local CharacterService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local DataService = require(Paths.Server.Data.DataService)

Players.CharacterAutoLoads = false

-- Moves a character so that they're standing above a part, usefull for spawning
function CharacterService.standOn(character: Model, platform: BasePart)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    character.WorldPivot = humanoidRootPart.CFrame
    character:PivotTo(
        platform.CFrame:ToWorldSpace(CFrame.new(0, character.Humanoid.HipHeight + (platform.Size + humanoidRootPart.Size).Y / 2, 0))
    )
end

function CharacterService.loadPlayer(player: Player)
    local character = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
    character.Name = player.Name
    character.Parent = Workspace
    player.Character = character

    -- Apply saved appearance
    CharacterUtil.applyAppearance(character, DataService.get(player, "CharacterAppearance"))

    local humanoid = character.Humanoid
    humanoid.WalkSpeed = CharacterConstants.WalkSpeed
    humanoid.JumpPower = CharacterConstants.JumpPower

    CharacterService.standOn(character, Workspace:FindFirstChildOfClass("SpawnLocation"))
end

return CharacterService
