local CharacterUtil = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Toggle = require(Shared.Toggle)
local Packages = ReplicatedStorage.Packages
local Maid = require(Packages.maid)
local ItemConstants = Shared.Constants.CharacterItems
local BodyTypeConstants = require(ItemConstants.BodyTypeConstants)

type Appearance = {
    BodyType: string,
}
export type CharacterAppearance = Appearance

local HIDEABLE_CLASSES = {
    BasePart = { Property = "Transparency", HideValue = 1 },
    Decal = { Property = "Transparency", HideValue = 1 },
    BillboardGui = { Property = "Enabled", HideValue = false },
}

local hidingSession = Maid.new()
local hidden: { [Instance]: { Property: string, UnhideValue: any } }?
local areCharactersHidden = Toggle.new(false, function(value)
    if value then
        hidden = {}
        hidingSession:GiveTask(Players.PlayerAdded:Connect(hidePlayer))
        for _, player in Players:GetPlayers() do
            hidePlayer(player)
        end
    else
        for instance, instructions in hidden do
            instance[instructions.Property] = instructions.UnhideValue
        end

        hidden = nil
        hidingSession:Cleanup()
    end
end)

function hideInstance(instance: Instance)
    -- Iterate through the classes rather than use ClassName in order to account for parent classes
    for class, instructions in HIDEABLE_CLASSES do
        if instance:IsA(class) then
            local property: string = instructions.Property

            hidden[instance] = { Property = property, UnhideValue = instance[property] }
            instance[property] = instructions.HideValue
        end
    end
end

function hideCharacter(char: Model)
    if char then
        hidingSession:GiveTask(char.DescendantAdded:Connect(hideInstance))
        for _, descendant in pairs(char:GetDescendants()) do
            hideInstance(descendant)
        end
    end
end

function hidePlayer(player: Player)
    hideCharacter(player.Character)
    hidingSession:GiveTask(player.CharacterAdded:Connect(hideCharacter))
end

function CharacterUtil.hideCharacters(requester: string)
    areCharactersHidden:Set(true, requester)
end

function CharacterUtil.showCharacters(requester: string)
    areCharactersHidden:Set(false, requester)
end

--[[
    Modifies a character's appearance based on their appearance description
    Partical description for changes, full descriptions for initialization
]]
function CharacterUtil.applyAppearance(character: Model, description: { [string]: string })
    local bodyType = description.BodyType
    if bodyType then
        character.Body.Main_Bone.Belly["Belly.001"].Position = Vector3.new(0, 1.319, -0) + BodyTypeConstants.All[bodyType].Height
    end
end

return CharacterUtil
