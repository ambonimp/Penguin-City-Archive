local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterItemConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants)

local assets = ReplicatedStorage.Assets.Character

local function doesModelContainerExist(issues, itemType: string): boolean
    local passed: boolean = true

    if not assets:FindFirstChild(CharacterItemConstants[itemType].AssetsPath) then
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
    local itemConstants = CharacterItemConstants[itemType]

    local models = assets[itemConstants.AssetsPath]
    for item in pairs(itemConstants.Items) do
        if not models:FindFirstChild(item) then
            table.insert(issues, string.format("%s character item model does not exist : %s", itemType, item))
        end
    end
end

local function doModelsHaveA(issues, itemType: string, descedant: string)
    local itemConstants = CharacterItemConstants[itemType]
    local items: { [string]: table } = itemConstants.Items

    for _, model in pairs(assets[itemConstants.AssetsPath]:GetChildren()) do
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
        doModelsHaveA(issues, "Hat", "AccessoryAttachment")
    end

    if doesModelContainerExist(issues, "Backpack") then
        doModelsExist(issues, "Backpack")
        doModelsHaveA(issues, "Backpack", "Handle")
        doModelsHaveA(issues, "Backpack", "AccessoryAttachment")
    end

    return issues
end
