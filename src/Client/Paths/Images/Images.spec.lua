local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Client.Images.Images)

return function()
    local issues: { string } = {}

    -- Grab all Images found in studio
    local foundImageIds: { [string]: Instance } = {}
    for _, directory: Instance in pairs({ StarterGui, ReplicatedStorage, Workspace }) do
        task.wait() -- Give the thread a moment to breathe, could be a lot of computation going on here!
        for _, descendant in pairs(directory:GetDescendants()) do
            if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
                local imageId = descendant.Image
                if imageId ~= "" then
                    foundImageIds[imageId] = descendant
                end
            end
        end
    end

    -- Write all stored imageIds into a dictionary for O(1) searching
    local storedImageIds: { [string]: boolean } = {}
    local function searchStoredImageIds(tbl: table)
        for _, value in pairs(tbl) do
            if typeof(value) == "table" then
                searchStoredImageIds(value)
            elseif typeof(value) == "string" then
                storedImageIds[value] = true
            end
        end
    end
    searchStoredImageIds(Images)

    -- Compare
    for imageId, instance in pairs(foundImageIds) do
        local isStored = storedImageIds[imageId] and true or false
        if not isStored then
            table.insert(
                issues,
                ("%s %q has an ImageId not stored internally in Images!"):format(instance.ClassName, instance:GetFullName())
            )
        end
    end

    return issues
end
