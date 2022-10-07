local CharacterUtil = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Maid = require(Packages.maid)
local Shared = ReplicatedStorage.Shared
local CharacterItems = require(Shared.Constants.CharacterItems)
local Toggle = require(Shared.Toggle)

local HIDEABLE_CLASSES = {
    BasePart = {
        { Name = "Transparency", HideValue = 1 },
        { Name = "CollisionGroupId", HideValue = PhysicsService:GetCollisionGroupId("HiddenCharacters") },
    },
    Decal = { Name = "Transparency", HideValue = 1 },
    BillboardGui = { Name = "Enabled", HideValue = false },
}

local assets = ReplicatedStorage.Assets.Character

-- Modify visibility
do
    local hidingSession = Maid.new()
    local hidden: { [Instance]: { { Property: string, UnhideValue: any } } }?
    local areCharactersHidden = Toggle.new(false, function(value)
        if value then
            hidden = {}
            hidingSession:GiveTask(Players.PlayerAdded:Connect(hidePlayer))
            for _, player in Players:GetPlayers() do
                hidePlayer(player)
            end
        else
            for instance, unhidingProperties in hidden do
                for _, property in unhidingProperties do
                    instance[property.Name] = property.UnhideValue
                end
            end

            hidden = nil
            hidingSession:Cleanup()
        end
    end)

    function hideInstance(instance: Instance)
        -- Iterate through the classes rather than use ClassName in order to account for parent classes
        for class, hiddingProperties in HIDEABLE_CLASSES do
            if instance:IsA(class) then
                hidden[instance] = {}
                for _, property in hiddingProperties do
                    local name: string = property.Name

                    table.insert(hidden[instance], { Name = name, UnhideValue = instance[name] })
                    instance[name] = property.HideValue
                end
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
end

-- Modify apperance
do
    local function applyAccessoryApperance(character: Model, type: string, accessories: { string })
        local categoryConstant = CharacterItems[type]

        local alreadyEquippedAccessories: { [string]: true } = {}
        for _, accessory in character:GetChildren() do
            if accessory:GetAttribute("AccessoryType") == type then
                if table.find(accessories, accessory.Name) then
                    alreadyEquippedAccessories[accessory.Name] = true
                else
                    accessory:Destroy()
                end
            end
        end

        for _, accessoryName: string in accessories do
            if not alreadyEquippedAccessories[accessoryName] and categoryConstant.Items[accessoryName] then
                local model: Accessory = assets[categoryConstant.InventoryPath][accessoryName]:Clone()

                local rigidConstraint = Instance.new("RigidConstraint")
                rigidConstraint.Attachment0 = model.Handle.AccessoryAttachment
                rigidConstraint.Attachment1 = character.Body.Main_Bone.Belly["Belly.001"].HEAD
                rigidConstraint.Parent = model

                model.Parent = character
            end
        end
    end

    local function applyClothingAppearance(character: Model, type: string, clothingName: string)
        for _, clothing in character:GetChildren() do
            if clothing:GetAttribute("ClothingType") == type then
                clothing:Destroy()
            end
        end

        if clothingName then
            local body = character.Body
            local bodyPosition = body.Position
            for _, pieceTemplate in assets[CharacterItems[type].InventoryPath][clothingName]:GetChildren() do
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
            character.Body.Main_Bone.Belly["Belly.001"].Position = Vector3.new(0, 1.319, -0)
                + CharacterItems.BodyType.Items[bodyType].Height
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
            for itemType, items in CharacterItems.Outfit.Items[outfit].Items do
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
end
return CharacterUtil
