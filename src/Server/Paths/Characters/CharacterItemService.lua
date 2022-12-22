local CharacterItemService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local DataService = require(Paths.Server.Data.DataService)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local Signal = require(Paths.Shared.Signal)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CharacterItemConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local DataUtil = require(Paths.Shared.Utils.DataUtil)

CharacterItemService.ItemEquipped = Signal.new() -- { player: Player, categoryName: string, itemName: string }
CharacterItemService.ItemUnequipped = Signal.new() -- { player: Player, categoryName: string, itemName: string }

local assets = ReplicatedStorage.Assets.Character

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CharacterItemService.Init()
    local function initAccessoryModels(type: string)
        for _, model: Model in pairs(assets[CharacterItemConstants[type].AssetsPath]:GetChildren()) do
            model:SetAttribute("AccessoryType", type)

            local handle: BasePart = model:FindFirstChild("Handle")
            -- CONTINUE: Handle does not exist, already caught in testing
            if not handle then
                continue
            end

            for _, descendant in pairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanCollide = false
                    descendant.Anchored = false
                    descendant.CanQuery = false
                    descendant.CanTouch = false
                    descendant.Massless = true

                    if descendant ~= handle then
                        InstanceUtil.tree("WeldConstraint", { Part0 = descendant, Part1 = handle, Parent = handle })
                    end
                end
            end
        end
    end

    local function initClothingModels(type: string)
        for _, model: Model in pairs(assets[CharacterItemConstants[type].AssetsPath]:GetChildren()) do
            for _, piece in pairs(model:GetChildren()) do
                piece:SetAttribute("ClothingType", type)
                if piece:IsA("BasePart") then
                    piece.CanCollide = false
                    piece.Anchored = false
                    piece.CanQuery = false
                    piece.CanTouch = false
                    piece.Massless = true
                end
            end
        end
    end

    initAccessoryModels("Hat")
    initAccessoryModels("Backpack")

    initClothingModels("Shirt")
    initClothingModels("Pants")
    initClothingModels("Shoes")
end

function CharacterItemService.doPlayersHaveMatchingCharacterAppearance(player1: Player, player2: Player)
    local items1 = CharacterItemService.getEquippedCharacterItems(player1)
    local items2 = CharacterItemService.getEquippedCharacterItems(player2)

    -- FALSE: Category count mismatch
    if TableUtil.length(items1) ~= TableUtil.length(items2) then
        return false
    end

    for categoryName1, itemNames1 in pairs(items1) do
        -- FALSE: itemNames count mismatch
        local itemNames2 = items2[categoryName1]
        if TableUtil.length(itemNames1) ~= TableUtil.length(itemNames2) then
            return false
        end

        for _, itemName in pairs(itemNames1) do
            -- FALSE: Missing itemName
            if not table.find(itemNames2, itemName) then
                return false
            end
        end
    end

    -- TRUE: Passed all our fail checks
    return true
end

function CharacterItemService.updateCharacterAppearance(player: Player)
    local character = player.Character
    if character then
        CharacterItemUtil.applyAppearance(character, CharacterItemService.getEquippedCharacterItems(player))
    end
end

function CharacterItemService.getEquippedCharacterItems(player: Player)
    local characterItems: { [string]: { string } } = {}
    for categoryName, itemNames in pairs(DataService.get(player, "CharacterAppearance")) do
        characterItems[categoryName] = TableUtil.toArray(itemNames)
    end

    return characterItems
end

--[[
    Does not check for ownership from `player` of the passed items/products

    data: `{ [categoryName]: { itemName } }`
]]
function CharacterItemService.setEquippedCharacterItems(player: Player, data: { [string]: { string } })
    -- Get our current items, and as we go we remove entries that are being kept
    local oldEquippedItems = CharacterItemService.getEquippedCharacterItems(player)

    -- Update stored data, verifying data at each stage
    for categoryName, itemNames in pairs(data) do
        -- ERROR: Bad categoryName
        local itemConstants = CharacterItemConstants[categoryName]
        if not itemConstants then
            error(("Passed a bad CategoryName %q"):format(categoryName))
        end

        -- ERROR: Bad ItemName
        for _, itemName in pairs(itemNames) do
            local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
            if not product then
                error(("Bad CharacterItem %s %s"):format(categoryName, itemNames))
            end
        end

        -- Update Data
        local address = ("CharacterAppearance.%s"):format(categoryName)
        local event = ("OnCharacterAppareanceChanged_%s"):format(categoryName)
        DataService.set(player, address, ArrayUtil.toDict(itemNames), event)

        -- Inform Equipped
        for _, itemName in pairs(itemNames) do
            CharacterItemService.ItemEquipped:Fire(player, categoryName, itemName)
        end
    end

    -- Inform Unequipped; we compare old vs new as this function is additive, not strict
    local newEquippedItems = CharacterItemService.getEquippedCharacterItems(player)
    for categoryName, itemNames in pairs(oldEquippedItems) do
        for _, itemName in pairs(itemNames) do
            local isUnequipped = not (newEquippedItems[categoryName] and table.find(newEquippedItems[categoryName], itemName))
            if isUnequipped then
                CharacterItemService.ItemUnequipped:Fire(player, categoryName, itemName)
            end
        end
    end

    -- Apply Changes
    CharacterItemService.updateCharacterAppearance(player)
end

function CharacterItemService.loadCharacter(character: Model)
    -- Apply saved appearance
    local appearance =
        DataUtil.readAsArray(DataService.get(Players:GetPlayerFromCharacter(character), "CharacterAppearance")) :: CharacterItemConstants.Appearance
    CharacterItemUtil.applyAppearance(character, appearance)
end

function CharacterItemService.loadPlayer(player: Player)
    for itemCategory, itemKeys in pairs(DataService.get(player, "CharacterAppearance")) do
        local found = {}

        for i, itemKey in pairs(itemKeys) do
            local address = ("CharacterAppearance.%s.%s"):format(itemCategory, i)

            -- Unequip any deprecated items
            local productId = ProductUtil.getCharacterItemProductId(itemCategory, itemKey)
            local success = pcall(ProductUtil.getProduct, ProductConstants.ProductType.CharacterItem, productId)

            if not success then
                warn(("unequipped removed %s %s on %s"):format(itemCategory, itemKey, player.Name))
                DataService.set(player, address, nil)
                continue
            end

            if not table.find(found, itemKey) then
                -- Clean up previously corruped data wheere you would have duplicate items equipped
                table.insert(found, itemKey)
            else
                DataService.set(player, address, nil)
                warn(("clean up corruped character appearance data, %s %s was unequipped on %s"):format(itemCategory, itemKey, player.Name))
            end
        end
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Communication
Remotes.bindFunctions({
    -- changes: `{ [categoryName]: { itemName } }`
    UpdateCharacterAppearance = function(client: Player, changes: { [string]: { string } })
        -- RETURN: Data is bad type
        if typeof(changes) ~= "table" then
            return
        end
        for key, strings in pairs(changes) do
            if typeof(key) ~= "string" then
                return
            end

            local arrayStrings = TypeUtil.toArray(strings, function(str)
                return typeof(str) == "string"
            end)
            if not arrayStrings then
                return
            end
        end

        -- Verify that every item that's being changed into is owned or free
        local allItemsAreValid = true
        for categoryName, items in pairs(changes) do
            local itemConstants = CharacterItemConstants[categoryName]
            if itemConstants and #items <= itemConstants.MaxEquippables then
                for _, itemKey in pairs(items) do
                    local product = ProductUtil.getCharacterItemProduct(categoryName, itemKey)
                    if not product or not (ProductUtil.isFree(product) or ProductService.hasProduct(client, product)) then
                        warn(("Invalid Character Items %q"):format(itemKey), items)
                        allItemsAreValid = false
                        break
                    end
                end
            end

            if not allItemsAreValid then
                break
            end
        end

        if allItemsAreValid then
            CharacterItemService.setEquippedCharacterItems(client, changes)
            return true
        end
    end,
})

return CharacterItemService
