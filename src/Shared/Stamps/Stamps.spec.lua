local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

local function verifyStamp(issues: { string }, stampModuleScript: ModuleScript, stamp: Stamps.Stamp)
    local issuePrefix = ("[%s - %s]"):format(stampModuleScript.Name, tostring(stamp.Id) or tostring(stamp.DisplayName) or "?")

    -- Id
    if stamp.Id and typeof(stamp.Id) == "string" and string.len(stamp.Id) > 0 then
        local typePrefix = string.lower(tostring(stamp.Type))
        if not StringUtil.startsWith(stamp.Id, typePrefix) then
            table.insert(issues, ("%s .Id must start with %q"):format(issuePrefix, typePrefix))
        end
    else
        table.insert(issues, ("%s needs a non-empty string .Id"):format(issuePrefix))
    end

    -- DisplayName
    if not (stamp.DisplayName and typeof(stamp.DisplayName) == "string" and string.len(stamp.DisplayName) > 0) then
        table.insert(issues, ("%s needs a non-empty string .DisplayName"):format(issuePrefix))
    end

    -- Description
    if not (stamp.Description and typeof(stamp.Description) == "string" and string.len(stamp.Description) > 0) then
        table.insert(issues, ("%s needs a non-empty string .Description"):format(issuePrefix))
    end

    -- Type
    if stamp.Type and typeof(stamp.Type) == "string" and string.len(stamp.Type) > 0 then
        if not StringUtil.startsWith(stampModuleScript.Name, stamp.Type) then
            table.insert(issues, ("%s .Type %q does not match the StampType ModuleScript it is under"):format(issuePrefix, stamp.Type))
        end
    else
        table.insert(issues, ("%s needs a non-empty string .Type"):format(issuePrefix))
    end

    -- Difficulty
    if stamp.Difficulty and typeof(stamp.Difficulty) == "string" and string.len(stamp.Difficulty) > 0 then
        if not table.find(Stamps.StampDifficulties, stamp.Difficulty) then
            table.insert(issues, ("%s .Difficulty %q is not a valid difficulty"):format(issuePrefix, stamp.Difficulty))
        end
    else
        table.insert(issues, ("%s needs a non-empty string .Difficulty"):format(issuePrefix))
    end

    -- ImageId
    if stamp.ImageId and typeof(stamp.ImageId) == "string" and string.len(stamp.ImageId) > 0 then
        if not StringUtil.startsWith(stamp.ImageId, "rbxassetid") then
            table.insert(issues, ("%s .ImageId %q is (likely) not a valid ImageId"):format(issuePrefix, stamp.ImageId))
        end
    else
        table.insert(issues, ("%s needs a non-empty string .ImageId"):format(issuePrefix))
    end

    -- Chapter
    for _, chapter in pairs(StampConstants.Chapters) do
        if chapter.StampType == stamp.Type then
            -- Metadata
            if chapter.LayoutByMetadataKey then
                local hasLayoutByMetadataKey = stamp.Metadata and stamp.Metadata[chapter.LayoutByMetadataKey] and true or false
                if not hasLayoutByMetadataKey then
                    table.insert(issues, ("%s needs Metadata with a %q key"):format(issuePrefix, chapter.LayoutByMetadataKey))
                end
            end
        end
    end
end

return function()
    local issues: { string } = {}

    -- Iterate each StampType, verifying it contains valid stamps
    local stampsModuleScripts = ReplicatedStorage.Shared.Stamps.StampTypes
    local setStampIds: { [string]: boolean }? = {}

    for _, stampType in pairs(Stamps.StampTypes) do
        local stampModuleScript = stampsModuleScripts:FindFirstChild(("%sStamps"):format(stampType))
        if stampModuleScript then
            local stamps = require(stampModuleScript)
            for _, stamp: Stamps.Stamp in pairs(stamps) do
                verifyStamp(issues, stampModuleScript, stamp)

                -- Verify UniqueId
                if setStampIds[stamp.Id] then
                    table.insert(issues, ("Stamp %q (%s) has a duplicate Id!"):format(stamp.DisplayName, stamp.Id))
                end
                setStampIds[stamp.Id] = true
            end
        else
            table.insert(issues, ("No StampTypes ModuleScript for %q"):format(stampType))
        end
    end

    -- Cleanup
    setStampIds = nil

    return issues
end
