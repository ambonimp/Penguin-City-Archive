local CharacterService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local Remotes = require(Paths.Shared.Remotes)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local DataService = require(Paths.Server.Data.DataService)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

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
end

Remotes.bindFunctions({
    UpdateCharacterAppearance = function(client, changes: { [string]: string })
        -- RETURN: No character
        local character = client.Character
        if not character then
            return
        end

        local inventory = DataService.get(client, "Inventory")
        -- Verify that every item that's being changed into is owned or free
        for category, item in changes do
            local constants = CharacterItems[category]
            if constants and (constants.All[item].Price == 0 or inventory[constants.Path][item]) then
                CharacterUtil.applyAppearance(character, { [category] = item })
                DataService.set(client, "Appearance." .. category, item, "OnCharacterAppareanceChanged_" .. category)
            end
        end
    end,
})

return CharacterService
