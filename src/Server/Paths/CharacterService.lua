local CharacterService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local Remotes = require(Paths.Shared.Remotes)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local DataService = require(Paths.Server.DataService)
local CharacterItems = Paths.Shared.Constants.CharacterItems
local CharacterItemConstants = {}

for _, module in CharacterItems:GetChildren() do
    CharacterItemConstants[string.gsub(module.Name, "Constants", "")] = require(module)
end

Players.CharacterAutoLoads = false

-- Moves a character so that they're standing above a part, usefull for spawning
function CharacterService.standOn(character: Model, platform: BasePart)
    if character then
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        character.WorldPivot = humanoidRootPart.CFrame
        character:PivotTo(
            platform.CFrame:ToWorldSpace(CFrame.new(0, character.Humanoid.HipHeight + (platform.Size + humanoidRootPart.Size).Y / 2, 0))
        )
    end
end

function CharacterService.loadPlayer(player: Player)
    local character = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
    character.Name = player.Name
    character.Parent = Workspace
    player.Character = character

    -- Apply saved appearance
    CharacterUtil.applyAppearance(character, DataService.get(player, "Appearance"))

    local humanoid = character.Humanoid
    humanoid.WalkSpeed = CharacterConstants.WalkSpeed
    humanoid.JumpPower = CharacterConstants.JumpPower

    CharacterService.standOn(character, Workspace:FindFirstChildOfClass("SpawnLocation"))
end

Remotes.bindFunctions({
    UpdateCharacterAppearance = function(client, changes: { [string]: string })
        local character = client.Character

        if character then
            local inventory = DataService.get(client, "Inventory")

            -- Verify that every item that's being changed into is owned or free
            for category, item in changes do
                local constants = CharacterItemConstants[category]
                if constants and (constants.All[item].Price == 0 or inventory[constants.Path][item]) then
                    CharacterUtil.applyAppearance(character, { [category] = item })
                    DataService.set(client, "Appearance." .. category, item, "OnCharacterAppareanceChanged_" .. category)
                end
            end
        end
    end,
})

return CharacterService
