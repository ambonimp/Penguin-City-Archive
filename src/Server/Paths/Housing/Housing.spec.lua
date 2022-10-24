local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local FurnitureConstants = require(Paths.Shared.Constants.HouseObjects.FurnitureConstants)

local assets = ReplicatedStorage.Assets.Housing

return function()
    local issues: { string } = {}

    local furnitudeModels: Folder = assets.Furniture
    for furnitureName, furnitureInfo in pairs(FurnitureConstants.Objects) do
        if not furnitureInfo.DefaultColor then
            table.insert(issues, ("Furniture: %s does not have a correct color value assigned"):format(furnitureName))
        end

        if not furnitureInfo.Type then
            table.insert(issues, ("Furniture: %s does not have a correct type assigned"):format(furnitureName))
        end

        if not furnitudeModels:FindFirstChild(furnitureName) then
            table.insert(issues, ("Furniture: %s does not have a model in %s"):format(furnitureName, furnitudeModels:GetFullName()))
        end
    end
    return issues
end
