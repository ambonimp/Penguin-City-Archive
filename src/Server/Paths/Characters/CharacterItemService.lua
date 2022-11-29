local CharacterItemService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local Remotes = require(Paths.Shared.Remotes)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local DataService = require(Paths.Server.Data.DataService)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local Signal = require(Paths.Shared.Signal)

CharacterItemService.ItemEquipped = Signal.new() -- { player: Player, categoryName: string, itemName: string }

local assets = ReplicatedStorage.Assets.Character

local function initAccessoryModels(type: string)
    for _, model: Model in pairs(assets[CharacterItems[type].AssetsPath]:GetChildren()) do
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
    for _, model: Model in pairs(assets[CharacterItems[type].AssetsPath]:GetChildren()) do
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

Remotes.bindFunctions({
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

        -- RETURN: No character
        local character = client.Character
        if not character then
            return
        end

        -- Verify that every item that's being changed into is owned or free
        for categoryName, items in pairs(changes) do
            local itemConstants = CharacterItems[categoryName]
            if itemConstants and #items <= itemConstants.MaxEquippables then
                local allItemsAreValid = true
                for _, itemKey in pairs(items) do
                    local product = ProductUtil.getCharacterItemProduct(categoryName, itemKey)
                    if not product or not (ProductUtil.isFree(product) or ProductService.hasProduct(client, product)) then
                        warn(("Invalid Character Items %q"):format(itemKey), items)
                        allItemsAreValid = false
                        break
                    end
                end

                if allItemsAreValid then
                    DataService.set(client, "CharacterAppearance." .. categoryName, items, "OnCharacterAppareanceChanged_" .. categoryName)
                    CharacterUtil.applyAppearance(character, { [categoryName] = items })

                    -- Inform
                    for _, itemName in pairs(items) do
                        CharacterItemService.ItemEquipped:Fire(client, categoryName, itemName)
                    end
                end
            end
        end
    end,
})

return CharacterItemService
