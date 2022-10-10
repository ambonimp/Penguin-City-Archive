local CharacterUtil = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Toggle = require(Shared.Toggle)
local Packages = ReplicatedStorage.Packages
local Maid = require(Packages.maid)
local ItemConstants = Shared.Constants.CharacterItems
local BodyTypeConstants = require(ItemConstants.BodyTypeConstants)
local PropertyStack = require(ReplicatedStorage.Shared.PropertyStack)
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
export type CharacterAppearance = {
    BodyType: string,
}

type HideProperty = { Name: string, Value: any, StackPriority: number }

local HIDEABLE_CLASSES: { [string]: { HideProperty } } = {
    BasePart = {
        { Name = "Transparency", Value = 1, StackPriority = 10 },
        { Name = "CollisionGroupId", Value = PhysicsService:GetCollisionGroupId("HiddenCharacters"), StackPriority = 10 },
    },
    Decal = { { Name = "Transparency", Value = 1, StackPriority = 10 } },
    BillboardGui = { { Name = "Enabled", Value = false, StackPriority = 10 } },
}
local MAX_PLAYER_FROM_CHARACTER_SEARCH_DEPTH = 2
local PROPERTY_STACK_KEY_HIDE = "CharacterUtil.Hide"
local PROPERTY_STACK_KEY_ETHEREAL = "CharacterUtil.Ethereal"
local DEFAULT_SCOPE = "Default"

local hidingSession = Maid.new()
local areCharactersHidden: typeof(Toggle.new(true, function() end))
local etherealToggles: { [Player]: typeof(Toggle.new(true, function() end)) } = {}
local etherealMaids: { [Player]: typeof(Maid.new()) } = {}
local etherealCollisionGroupId = PhysicsService:GetCollisionGroupId("EtherealCharacters")

-------------------------------------------------------------------------------
-- Internal Methods
-------------------------------------------------------------------------------

local function etherealInstance(player: Player, instance: Instance)
    if instance:IsA("BasePart") then
        PropertyStack.setProperty(instance, "CollisionGroupId", etherealCollisionGroupId, PROPERTY_STACK_KEY_ETHEREAL)
        etherealMaids[player]:GiveTask(function()
            PropertyStack.clearProperty(instance, "CollisionGroupId", PROPERTY_STACK_KEY_ETHEREAL)
        end)
    end
end

local function etherealCharacter(player: Player, character: Model)
    if character then
        etherealMaids[player]:GiveTask(character.DescendantAdded:Connect(function(descendant)
            etherealInstance(player, descendant)
        end))
        for _, descendant in pairs(character:GetDescendants()) do
            etherealInstance(player, descendant)
        end
    end
end

local function etherealPlayer(player: Player)
    etherealMaids[player]:GiveTask(player.CharacterAdded:Connect(function(character)
        etherealCharacter(player, character)
    end))
    etherealCharacter(player, player.Character)
end

local function hideInstance(instance: Instance)
    -- Iterate through the classes rather than use ClassName in order to account for parent classes
    for className, hidingProperties in pairs(HIDEABLE_CLASSES) do
        if instance:IsA(className) then
            for _, hideProperty in pairs(hidingProperties) do
                PropertyStack.setProperty(
                    instance,
                    hideProperty.Name,
                    hideProperty.Value,
                    PROPERTY_STACK_KEY_HIDE,
                    hideProperty.StackPriority
                )
            end
        end
    end
end

local function hideCharacter(character: Model)
    if character then
        hidingSession:GiveTask(character.DescendantAdded:Connect(hideInstance))
        for _, descendant in pairs(character:GetDescendants()) do
            hideInstance(descendant)
        end
    end
end

local function hidePlayer(player: Player)
    hidingSession:GiveTask(player.CharacterAdded:Connect(hideCharacter))
    hideCharacter(player.Character)
end

local function showInstance(instance: Instance)
    -- Iterate through the classes rather than use ClassName in order to account for parent classes
    for className, hidingProperties in pairs(HIDEABLE_CLASSES) do
        if instance:IsA(className) then
            for _, hideProperty in pairs(hidingProperties) do
                PropertyStack.clearProperty(instance, hideProperty.Name, PROPERTY_STACK_KEY_HIDE)
            end
        end
    end
end

local function showCharacter(character: Model)
    if character then
        for _, descendant in pairs(character:GetDescendants()) do
            showInstance(descendant)
        end
    end
end

local function showPlayer(player: Player)
    showCharacter(player.Character)
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

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

function CharacterUtil.getPlayerFromCharacterPart(part: BasePart, mustBeHumanoidRootPart: boolean?)
    -- RETURN: Must be root part and is not
    if mustBeHumanoidRootPart and part.Name ~= "HumanoidRootPart" then
        return
    end

    local character: Model
    for _ = 1, MAX_PLAYER_FROM_CHARACTER_SEARCH_DEPTH do
        part = part.Parent
        character = part and part:IsA("Model") and part :: Model

        if character then
            return Players:GetPlayerFromCharacter(character)
        elseif not part then
            return nil
        end
    end

    return nil
end

--[[
    When a character is ethereal, it does not collide with any other character.
    Can optionally pass `scope`, so .setEtheral calls in multiple contexts won't override one another - uses an internal Toggle
]]
function CharacterUtil.setEthereal(player: Player, isEthereal: boolean, scope: string?)
    scope = scope or DEFAULT_SCOPE

    -- RETURN: Nothing to update or change
    local toggle = etherealToggles[player]
    if not toggle and not isEthereal then
        return
    end

    -- Create toggle
    if not toggle then
        toggle = Toggle.new(false, function(isEtherealToggle)
            if isEtherealToggle then
                -- Ethereal time baby
                etherealMaids[player] = Maid.new()
                etherealPlayer(player)
                return
            end

            -- Revert
            local etherealMaid = etherealMaids[player]
            if etherealMaid then
                etherealMaid:Destroy()
                etherealMaids[player] = nil
            end
            etherealToggles[player] = nil
        end)
        etherealToggles[player] = toggle
    end

    -- Set Toggle
    toggle:Set(isEthereal, scope)
end

--[[
    Gets all characters currently loaded in. Remember that any of these characters could get streamed out at any moment!
]]
function CharacterUtil.getAllCharacters()
    local characters: { Model } = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(characters, player.Character)
    end
    return characters
end

-- Returns true if the passed character is colliding with any other character in the world
function CharacterUtil.isCollidingWithOtherCharacter(character: Model)
    local collideableParts: { BasePart } = InstanceUtil.getChildren(character, function(child: BasePart)
        return child:IsA("BasePart") and child.CanCollide == true
    end)

    for _, collideablePart in pairs(collideableParts) do
        local touchingParts = collideablePart:GetTouchingParts()
        for _, touchingPart in pairs(touchingParts) do
            if CharacterUtil.getPlayerFromCharacterPart(touchingPart) then
                return true
            end
        end
    end

    return false
end

function CharacterUtil.anchor(character: Model)
    local root = character.HumanoidRootPart
    if root then
        root.Anchored = true
    end
end

function CharacterUtil.unanchor(character: Model)
    local root = character.HumanoidRootPart
    if root then
        root.Anchored = false
    end
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    -- Cleanup Cache
    local etherealToggle = etherealToggles[player]
    if etherealToggle then
        etherealToggle:CallOnToggled(false) -- Force disable ethereal, and therefore clear cache
    end
end)

areCharactersHidden = Toggle.new(false, function(value)
    if value then
        hidingSession:GiveTask(Players.PlayerAdded:Connect(hidePlayer))
        for _, player in pairs(Players:GetPlayers()) do
            hidePlayer(player)
        end
    else
        hidingSession:Cleanup()

        for _, player in pairs(Players:GetPlayers()) do
            showPlayer(player)
        end
    end
end)

return CharacterUtil
