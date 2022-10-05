local CharacterItemService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local Remotes = require(Paths.Shared.Remotes)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local DataService = require(Paths.Server.Data.DataService)

local assets = ReplicatedStorage.Assets.Character

for _, hat: Model in assets.Hats:GetChildren() do
    hat:SetAttribute("AccessoryType", "Hat")

    local handle: BasePart = hat:FindFirstChild("Handle")
    -- CONTINUE: Handle does not exist, already caught in testing
    if not handle then
        continue
    end

    for _, descendant in hat:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.Massless = true

            if descendant ~= handle then
                InstanceUtil.tree("WeldConstraint", { Part0 = descendant, Part1 = handle, Parent = handle })
            end
        end
    end
end

Remotes.bindFunctions({
    UpdateCharacterAppearance = function(client, changes: { [string]: { string } })
        -- RETURN: No character
        local character = client.Character
        if not character then
            return
        end

        local inventory = DataService.get(client, "Inventory")

        -- Verify that every item that's being changed into is owned or free
        for category, items in changes do
            local constants = CharacterItems[category]
            if constants and #items < constants.MaxEquippables then
                local allItemsAreValid = true
                for _, item in items do
                    if not (constants.Items[item].Price == 0 or inventory[constants.InventoryPath][item]) then
                        allItemsAreValid = false
                        break
                    end
                end

                if allItemsAreValid then
                    DataService.set(client, "CharacterAppearance." .. category, items, "OnCharacterAppareanceChanged_" .. category)
                    CharacterUtil.applyAppearance(character, { [category] = items })
                end
            end
        end
    end,
})

return CharacterItemService
