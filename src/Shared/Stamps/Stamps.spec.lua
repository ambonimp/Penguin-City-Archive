local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Images = require(ReplicatedStorage.Shared.Images.Images)

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

    -- Tiered
    if stamp.IsTiered then
        if typeof(stamp.IsTiered) ~= "boolean" then
            table.insert(issues, ("%s .Tiered must be boolean!"):format(issuePrefix))
        end

        -- Validate Tiers
        if stamp.Tiers then
            local lastTierValue = -1
            for _, stampTier in pairs(Stamps.StampTiers) do
                local tierValue = stamp.Tiers[stampTier]
                if tierValue then
                    if tierValue <= lastTierValue then
                        table.insert(
                            issues,
                            ("%s .Tiers.%s value is smaller than the previous tier! (Or is less than 0)"):format(issuePrefix, stampTier)
                        )
                    end
                    if tierValue ~= math.floor(tierValue) then
                        table.insert(issues, ("%s .Tiers.%s value must be an integer"):format(issuePrefix, stampTier))
                    end
                    lastTierValue = tierValue
                else
                    table.insert(issues, ("%s missing .Tiers.%s"):format(issuePrefix, stampTier))
                end
            end
        else
            table.insert(issues, ("%s missing .Tiers"):format(issuePrefix))
        end
    end

    -- DisplayName
    if not (stamp.DisplayName and typeof(stamp.DisplayName) == "string" and string.len(stamp.DisplayName) > 0) then
        table.insert(issues, ("%s needs a non-empty string .DisplayName"):format(issuePrefix))
    end

    -- Description
    if stamp.IsTiered then
        if not (stamp.Description and typeof(stamp.Description) == "table") then
            table.insert(issues, ("%s needs a table .Description for the different tiers"):format(issuePrefix))
        else
            for key, value in pairs(stamp.Description) do
                if not table.find(Stamps.StampTiers, key) then
                    table.insert(issues, ("%s .Description key %q does not match a StampTier"):format(issuePrefix, tostring(key)))
                end
                if not (typeof(value) == "string" and string.len(value) > 0) then
                    table.insert(issues, ("%s needs a non-empty string in .Description.%s"):format(issuePrefix, tostring(key)))
                end
            end
        end
    else
        if not (stamp.Description and typeof(stamp.Description) == "string" and string.len(stamp.Description) > 0) then
            table.insert(issues, ("%s needs a non-empty string .Description"):format(issuePrefix))
        end
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
    if stamp.IsTiered then
        if stamp.Difficulty then
            table.insert(issues, ("%s .Difficulty is null and void as it is tiered!"):format(issuePrefix))
        end
    else
        if stamp.Difficulty and typeof(stamp.Difficulty) == "string" and string.len(stamp.Difficulty) > 0 then
            if not table.find(Stamps.StampDifficulties, stamp.Difficulty) then
                table.insert(issues, ("%s .Difficulty %q is not a valid difficulty"):format(issuePrefix, stamp.Difficulty))
            end
        else
            table.insert(issues, ("%s needs a non-empty string .Difficulty"):format(issuePrefix))
        end
    end

    -- ImageId
    if stamp.IsTiered then
        if not (stamp.ImageId and typeof(stamp.ImageId) == "table") then
            table.insert(issues, ("%s needs a table .ImageId for the different tiers"):format(issuePrefix))
        else
            for _, stampTier in pairs(Stamps.StampTiers) do
                local imageId = stamp.ImageId[stampTier]
                if imageId then
                    if not (typeof(imageId) == "string" and string.len(imageId) > 0) then
                        table.insert(issues, ("%s needs a non-empty string in .ImageId.%s"):format(issuePrefix, tostring(stampTier)))
                    end
                else
                    table.insert(issues, ("%s .ImageId key %q missing"):format(issuePrefix, stampTier))
                end
            end
        end
    else
        if stamp.ImageId and typeof(stamp.ImageId) == "string" and string.len(stamp.ImageId) > 0 then
            if not StringUtil.startsWith(stamp.ImageId, "rbxassetid") then
                table.insert(issues, ("%s .ImageId %q is (likely) not a valid ImageId"):format(issuePrefix, stamp.ImageId))
            end
        else
            table.insert(issues, ("%s needs a non-empty string .ImageId"):format(issuePrefix))
        end
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
    do
        local stampsModuleScripts = ReplicatedStorage.Shared.Stamps.StampTypes
        local setStampIds: { [string]: boolean }? = {}

        for _, stampType in pairs(Stamps.StampTypes) do
            local stampModuleScript = stampsModuleScripts:FindFirstChild(("%sStamps"):format(stampType))
            if stampModuleScript then
                local stamps = require(stampModuleScript)

                -- Non-array
                if #stamps ~= TableUtil.length(stamps) then
                    table.insert(issues, ("Stamps table %q is not an array!"):format(stampModuleScript.Name))
                end

                for key, stamp: Stamps.Stamp in pairs(stamps) do
                    -- Key must be numeric
                    if not tonumber(key) then
                        table.insert(issues, ("Stamp %q (%s) has a non-numeric id as it's key!"):format(stamp.DisplayName, stamp.Id))
                    end

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
    end

    -- Verify chapter structure can be called without error
    do
        for i, chapter in pairs(StampConstants.Chapters) do
            if chapter.StampType then
                local success, err = pcall(StampUtil.getChapterStructure, chapter)
                if not success then
                    table.insert(issues, ("Error when getting chapter structure %d (%q): %s"):format(i, chapter.StampType, tostring(err)))
                end
            end
        end
    end

    -- Verify Images
    for _, stampType in pairs(Stamps.StampTypes) do
        local images = Images.Stamps.Types[stampType]
        if images then
            if not (images.Background and images.Border and images.Pattern and images.Shine) then
                table.insert(issues, "Images.Stamps.Types.%s does not have all four required entries!")
            end
        else
            table.insert(issues, ("No Images.Stamps.Types.%s exists! :o"):format(stampType))
        end
    end

    -- Difficulty + Tier Colors
    for _, stampDifficulty in pairs(Stamps.StampDifficulties) do
        if not StampConstants.DifficultyColors[stampDifficulty] then
            table.insert(issues, ("Missing Difficulty color %q"):format(stampDifficulty))
        end
    end
    for _, stampTier in pairs(Stamps.StampTiers) do
        if not StampConstants.TierColors[stampTier] then
            table.insert(issues, ("Missing Tier color %q"):format(stampTier))
        end
    end

    return issues
end
