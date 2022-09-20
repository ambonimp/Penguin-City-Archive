local Characters = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)

Players.CharacterAutoLoads = false

--[[
    Moves a character so that they're standing above a part, usefull for spawning
]]
function Characters.standOn(character: Model, platform: BasePart)
    if character then
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        character.WorldPivot = humanoidRootPart.CFrame
        character:PivotTo(
            platform.CFrame:ToWorldSpace(CFrame.new(0, character.Humanoid.HipHeight + (platform.Size + humanoidRootPart.Size).Y / 2, 0))
        )
    end
end

function Characters.loadPlayer(player: Player)
    local character = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
    character.Name = player.Name
    character.Parent = Workspace
    player.Character = character

    local humanoid = character.Humanoid
    humanoid.WalkSpeed = CharacterConstants.WalkSpeed
    humanoid.JumpPower = CharacterConstants.JumpPower

    Characters.standOn(character, Workspace:FindFirstChildOfClass("SpawnLocation"))
end

function Characters.unloadPlayer() end

return Characters
