local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Client.Images.Images)

local PLACEHOLDER_IMAGE_ID = "rbxasset://textures/ui/GuiImagePlaceholder.png"

return function()
    local issues: { string } = {}

    local ignoreDirectories: { Instance } = { ReplicatedStorage.VoldexAdmin }

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
    local storedImageIds: { [string]: string } = {
        [PLACEHOLDER_IMAGE_ID] = "Default_Placeholder",
    }
    local function searchStoredImageIds(tblKey: string?, tbl: table)
        for key, value in pairs(tbl) do
            if typeof(value) == "table" then
                searchStoredImageIds(key, value)
            elseif typeof(value) == "string" then
                local locationString = ("%s_%s"):format(tblKey, key)
                if storedImageIds[value] then
                    table.insert(issues, ("Duplicate Stored ImageIds %s and %s"):format(storedImageIds[value], locationString))
                end
                storedImageIds[value] = locationString
            end
        end
    end
    searchStoredImageIds("Images", Images)

    -- Compare
    for imageId, instance in pairs(foundImageIds) do
        local isStored = storedImageIds[imageId] and true or false
        if not isStored then
            local doIgnore = false
            for _, ignoreDirectory in pairs(ignoreDirectories) do
                if instance:IsDescendantOf(ignoreDirectory) then
                    doIgnore = true
                    break
                end
            end

            if not doIgnore then
                table.insert(
                    issues,
                    ("%s %q has an ImageId not stored internally in Images!"):format(instance.ClassName, instance:GetFullName())
                )
            end
        end
    end

    return issues
end
