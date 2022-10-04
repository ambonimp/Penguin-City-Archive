local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)

local assets = ReplicatedStorage.Assets.Character

local function doesModelContainerExist(issues, itemType: string): boolean
    local passed: boolean = true

    if not assets:FindFirstChild(CharacterItems[itemType].InventoryPath) then
        table.insert(
            issues,
            string.format(
                "Character item models should be stored in a folder in ReplicatedStorage.Character in a folder named after their inventory path - % models weren't found",
                itemType
            )
        )

        passed = false
    end

    return passed
end

local function doModelsExist(issues, itemType: string)
    local itemConstants = CharacterItems[itemType]

    local models = assets[itemConstants.InventoryPath]
    for item in itemConstants.All do
        -- CONTINUE: No item doesn't need an item
        if item == "None" then
            continue
        end
        if not models:FindFirstChild(item) then
            table.insert(issues, string.format("%s character item model does not exist : %s", itemType, item))
        end
    end
end

local function doModelsHaveA(issues, itemType: string, descedant: string)
    local itemConstants = CharacterItems[itemType]
    local items: { [string]: table } = itemConstants.All

    for _, model in assets[itemConstants.InventoryPath]:GetChildren() do
        local name = model.Name
        if items[name] and not InstanceUtil.findFirstDescendant(model, descedant) then
            table.insert(
                issues,
                string.format("%s character item models require a %s child : Item %s is missing one", itemType, descedant, name)
            )
        end
    end
end

return function()
    local issues: { string } = {}

    if doesModelContainerExist(issues, "Hat") then
        doModelsExist(issues, "Hat")
        doModelsHaveA(issues, "Hat", "Handle")
        doModelsHaveA(issues, "Hat", "HatAttachment")
    end

    return issues
end
