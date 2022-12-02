local CharacterItemsUtil = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local CharacterItems = require(Shared.Constants.CharacterItems)

local characterAssets = ReplicatedStorage.Assets.Character

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

--[[
    Adds `appearance` to `character`

    - `isStrict`: Instead of adding `appearance`, it *sets* `appearance` (aka will *remove* other character items)
]]
function CharacterItemsUtil.applyAppearance(
    character: Model,
    appearance: CharacterItems.Appearance,
    isStrict: boolean?
): CharacterItems.Appearance
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

    local hats = appearance.Hat or (isStrict and {})
    if hats then
        applyAccessoryApperance(character, "Hat", hats)
    end

    local backpacks = appearance.Backpack or (isStrict and {})
    if backpacks then
        applyAccessoryApperance(character, "Backpack", backpacks)
    end

    local shirt = appearance.Shirt or (isStrict and {})
    if shirt then
        shirt = shirt[1]
        applyClothingAppearance(character, "Shirt", shirt)
    end

    local pants = appearance.Pants or (isStrict and {})
    if pants then
        pants = pants[1]
        applyClothingAppearance(character, "Pants", pants)
    end

    local shoes = appearance.Shoes or (isStrict and {})
    if shoes then
        shoes = shoes[1]
        applyClothingAppearance(character, "Shoes", shoes)
    end

    return appearance
end

return CharacterItemsUtil
