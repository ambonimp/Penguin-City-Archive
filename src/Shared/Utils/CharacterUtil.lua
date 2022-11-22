local CharacterUtil = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.Shared
local Toggle = require(Shared.Toggle)
local Maid = require(ReplicatedStorage.Packages.maid)
local CharacterConstants = require(Shared.Constants.CharacterConstants)
local CharacterItems = require(Shared.Constants.CharacterItems)
local PropertyStack = require(ReplicatedStorage.Shared.PropertyStack)
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
local CollisionsConstants = require(ReplicatedStorage.Shared.Constants.CollisionsConstants)

export type CharacterAppearance = {
    BodyType: string,
}

type HideProperty = { Name: string, Value: any, StackPriority: number }

local HIDEABLE_CLASSES: { [string]: { HideProperty } } = {
    BasePart = {
        { Name = "Transparency", Value = 1, StackPriority = 10 },
        {
            Name = "CollisionGroupId",
            Value = PhysicsService:GetCollisionGroupId(CollisionsConstants.Groups.HiddenCharacters),
            StackPriority = 10,
        },
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
local etherealCollisionGroupId = PhysicsService:GetCollisionGroupId(CollisionsConstants.Groups.EtherealCharacters)
local isCollidingWithOtherCharacterOverlapParams = OverlapParams.new()
local characterAssets = ReplicatedStorage.Assets.Character

-------------------------------------------------------------------------------
-- Ethereal
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

-------------------------------------------------------------------------------
-- Hide/Show Characters
-------------------------------------------------------------------------------

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

function CharacterUtil.hideCharacters(requester: string)
    areCharactersHidden:Set(true, requester)
end

function CharacterUtil.showCharacters(requester: string)
    areCharactersHidden:Set(false, requester)
end

-------------------------------------------------------------------------------
-- Appearance
-------------------------------------------------------------------------------

local function applyAccessoryApperance(character: Model, type: string, accessories: { string })
    local categoryConstant = CharacterItems[type]

    local alreadyEquippedAccessories: { [string]: true } = {}
    for _, accessory in pairs(character:GetChildren()) do
        if accessory:GetAttribute("AccessoryType") == type then
            if table.find(accessories, accessory.Name) then
                alreadyEquippedAccessories[accessory.Name] = true
            else
                accessory:Destroy()
            end
        end
    end

    for _, accessoryName: string in pairs(accessories) do
        if not alreadyEquippedAccessories[accessoryName] and categoryConstant.Items[accessoryName] then
            local model: Accessory = characterAssets[categoryConstant.AssetsPath][accessoryName]:Clone()

            local rigidConstraint = Instance.new("RigidConstraint")
            rigidConstraint.Attachment0 = model.Handle.AccessoryAttachment
            rigidConstraint.Attachment1 = character.Body.Main_Bone.Belly["Belly.001"].HEAD
            rigidConstraint.Parent = model

            model.Parent = character
        end
    end
end

local function applyClothingAppearance(character: Model, type: string, clothingName: string)
    for _, clothing in pairs(character:GetChildren()) do
        if clothing:GetAttribute("ClothingType") == type then
            clothing:Destroy()
        end
    end

    if clothingName then
        local body = character.Body
        local bodyPosition = body.Position
        for _, pieceTemplate in pairs(characterAssets[CharacterItems[type].AssetsPath][clothingName]:GetChildren()) do
            local piece = pieceTemplate:Clone()
            piece.Position = bodyPosition
            piece.Parent = character

            local weldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Part0 = body
            weldConstraint.Part1 = piece
            weldConstraint.Parent = piece
        end
    end
end

function CharacterUtil.applyAppearance(character: Model, appearance: CharacterItems.Appearance): CharacterItems.Appearance
    local bodyType = appearance.BodyType
    if bodyType then
        bodyType = bodyType[1]
        character.Body.Main_Bone.Belly["Belly.001"].Position = Vector3.new(0, 1.319, -0) + CharacterItems.BodyType.Items[bodyType].Height
    end

    local furColor = appearance.FurColor
    if furColor then
        furColor = furColor[1]

        local color = CharacterItems.FurColor.Items[furColor].Color
        character.Body.Color = color
        character.Arms.Color = color
        character.EyeLids.Color = color
    end

    local outfit = appearance.Outfit
    if outfit then
        outfit = outfit[1]
        for itemType, items in pairs(CharacterItems.Outfit.Items[outfit].Items) do
            appearance[itemType] = items
        end
        appearance.Outfit = nil
    end

    local hats = appearance.Hat
    if hats then
        applyAccessoryApperance(character, "Hat", hats)
    end

    local backpacks = appearance.Backpack
    if backpacks then
        applyAccessoryApperance(character, "Backpack", backpacks)
    end

    local shirt = appearance.Shirt
    if shirt then
        shirt = shirt[1]
        applyClothingAppearance(character, "Shirt", shirt)
    end

    local pants = appearance.Pants
    if pants then
        pants = pants[1]
        applyClothingAppearance(character, "Pants", pants)
    end

    local shoes = appearance.Shoes
    if shoes then
        shoes = shoes[1]
        applyClothingAppearance(character, "Shoes", shoes)
    end

    return appearance
end

-------------------------------------------------------------------------------
-- Misc API
-------------------------------------------------------------------------------

function CharacterUtil.freeze(character: Model)
    character.Humanoid.WalkSpeed = 0
end

function CharacterUtil.unfreeze(character: Model)
    character.Humanoid.WalkSpeed = CharacterConstants.WalkSpeed
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
-- Ignores the different collision groups we have for characters.
function CharacterUtil.isCollidingWithOtherCharacter(character: Model)
    local collideableParts: { BasePart } = InstanceUtil.getChildren(character, function(child: BasePart)
        return child:IsA("BasePart") and child.CanCollide == true
    end)

    isCollidingWithOtherCharacterOverlapParams.FilterDescendantsInstances = { character }
    isCollidingWithOtherCharacterOverlapParams.FilterType = Enum.RaycastFilterType.Blacklist

    for _, collideablePart in pairs(collideableParts) do
        local partsInCollideablePart =
            Workspace:GetPartBoundsInBox(collideablePart.CFrame, collideablePart.Size, isCollidingWithOtherCharacterOverlapParams)
        for _, touchingPart in pairs(partsInCollideablePart) do
            if CharacterUtil.getPlayerFromCharacterPart(touchingPart) then
                return true
            end
        end
    end

    return false
end

function CharacterUtil.getHumanoidRootPart(player: Player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart") or nil
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
