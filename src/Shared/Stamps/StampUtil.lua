local StampUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type ChapterStructure = {
    Layout: { [string]: { Stamps.Stamp } },
    Display: { [string]: {
        Text: string?,
        ImageId: string?,
    } },
} -- Key in Layout <==> Key in Display

local CHAPTER_LAYOUT_TYPE_BY_STAMP_TYPE: { [string]: { Stamps.StampType } } = {
    Simple = { "Clothing", "Igloo", "Pets" },
    Text = { "Events", "Location" },
    Icon = { "Minigame" },
}

local totalStamps: number

function StampUtil.getStampFromId(stampId: string)
    -- Infer StampType
    local stampType: Stamps.StampType
    for _, someStampType in pairs(Stamps.StampTypes) do
        if StringUtil.startsWith(stampId, string.lower(someStampType)) then
            stampType = someStampType
            break
        end
    end

    -- WARN: Definitely a bad stampId
    if not stampType then
        warn(("Bad stampId %q; not prefixed with a proper stampType (lowercase)"):format(stampId))
        return nil
    end

    for _, stamp in pairs(StampUtil.getStampsFromType(stampType)) do
        if stamp.Id == stampId then
            return stamp
        end
    end

    warn(("Bad stampId %q; could not find in %q Stamps"):format(stampId, stampType))
    return nil
end

function StampUtil.getStampsFromType(stampType: Stamps.StampType): { Stamps.Stamp }
    return require(ReplicatedStorage.Shared.Stamps.StampTypes:FindFirstChild(("%sStamps"):format(stampType)))
end

function StampUtil.getTotalStamps()
    return totalStamps
end

function StampUtil.isTierCoveredByTier(ourTier: Stamps.StampTier, checkAgainstTier: Stamps.StampTier)
    local ourIndex = table.find(Stamps.StampTiers, ourTier)
    local checkAgainstIndex = table.find(Stamps.StampTiers, checkAgainstTier)

    return ourIndex >= checkAgainstIndex
end

function StampUtil.getTierFromProgress(stamp: Stamps.Stamp, progress: number)
    if not stamp.IsTiered then
        error(("Stamp %q is not tiered!"):format(stamp.Id))
    end

    local bestStampTier: string | nil
    for _, stampTier in pairs(Stamps.StampTiers) do
        local stampValue = stamp.Tiers[stampTier]
        if progress >= stampValue then
            bestStampTier = stampTier
        else
            break
        end
    end
    return bestStampTier
end

-- Funnels multiple data types for a stamps progress into a number
function StampUtil.calculateProgressNumber(stamp: Stamps.Stamp, stampTierOrProgress: Stamps.StampTier | number | nil): number
    if stamp.IsTiered then
        stampTierOrProgress = stampTierOrProgress or Stamps.StampTiers[1]

        if typeof(stampTierOrProgress) == "string" then
            return stamp.Tiers[stampTierOrProgress]
        else
            return stampTierOrProgress
        end
    else
        return 0
    end
end

local function createChapterLayoutFromMetadata(stamps: { Stamps.Stamp }, metadataKey: string)
    local layout: { [string]: { Stamps.Stamp } } = {}
    for _, stamp in pairs(stamps) do
        -- ERROR: Missing value
        local metadataValue = stamp.Metadata and stamp.Metadata[metadataKey]
        if not metadataValue then
            error(("Stamp %q missing metadata key %q"):format(stamp.Id, metadataKey))
        end

        layout[metadataValue] = layout[metadataValue] or {}
        table.insert(layout[metadataValue], stamp)
    end

    return layout
end

local function createChapterDisplayFromLayout(layout: { [string]: { Stamps.Stamp } }, useIcon: boolean)
    local display: { [string]: {
        Text: string,
        ImageId: string?,
    } } = {}

    for key, _ in pairs(layout) do
        local text = StringUtil.getFriendlyString(key)
        local icon = Images.StampBook.Titles[key]

        -- WARN: Expects icon!
        if useIcon and not icon then
            warn(("Missing Images.StampBook.Titles.%s"):format(key))
        end

        display[key] = {
            ImageId = icon,
            Text = text,
        }
    end

    return display
end

local function createMetaChapterStructure(chapter: StampConstants.Chapter, stamps: { Stamps.Stamp }, useIcon: boolean)
    local layout = createChapterLayoutFromMetadata(stamps, chapter.LayoutByMetadataKey)
    local display = createChapterDisplayFromLayout(layout, useIcon)

    local chapterStructure: ChapterStructure = {
        Layout = layout,
        Display = display,
    }
    return chapterStructure
end

local function createSimpleChapterStructure(chapter: StampConstants.Chapter, stamps: { Stamps.Stamp })
    local layout = { All = stamps }
    local display = { All = {
        Text = chapter.DisplayName,
    } }

    local chapterStructure: ChapterStructure = {
        Layout = layout,
        Display = display,
    }
    return chapterStructure
end

-- Must be a chapter with a `StampType`
function StampUtil.getChapterStructure(chapter: StampConstants.Chapter)
    -- ERROR: No stamp type
    local stampType = chapter.StampType
    if not stampType then
        error(("Chapter %s cannot be laid out"):format(chapter.DisplayName))
    end

    local stamps = StampUtil.getStampsFromType(stampType)

    -- Simple
    if table.find(CHAPTER_LAYOUT_TYPE_BY_STAMP_TYPE.Simple, stampType) then
        return createSimpleChapterStructure(chapter, stamps)
    end

    -- Text
    if table.find(CHAPTER_LAYOUT_TYPE_BY_STAMP_TYPE.Text, stampType) then
        return createMetaChapterStructure(chapter, stamps, false)
    end

    -- Icon
    if table.find(CHAPTER_LAYOUT_TYPE_BY_STAMP_TYPE.Icon, stampType) then
        return createMetaChapterStructure(chapter, stamps, true)
    end

    error(("Don't know how to layout chapter %s"):format(chapter.DisplayName))
end

function StampUtil.getTotalChapterPages(chapterStructure: ChapterStructure, stampsPerPage: number)
    local totalPages = 0
    for _, stamps in pairs(chapterStructure.Layout) do
        totalPages += math.ceil(#stamps / stampsPerPage)
    end

    return totalPages
end

function StampUtil.getChapterPage(chapterStructure: ChapterStructure, stampsPerPage: number, pageNumber: number)
    -- WARN: Big page number
    local totalPages = StampUtil.getTotalChapterPages(chapterStructure, stampsPerPage)
    if pageNumber > totalPages then
        warn(("%d is too large! Total pages is %d"):format(pageNumber, totalPages))
        pageNumber = totalPages
    end

    -- Sort alphabetically
    local chapterKeys = TableUtil.getKeys(chapterStructure.Display)
    table.sort(chapterKeys)

    local state = {
        Countdown = pageNumber, -- Final when this reaches 1
        ChapterIndex = 1,
        ChapterKey = chapterKeys[1],
        ChapterSection = 1,
    }
    while state.Countdown > 1 do
        -- Calculate total stamps in next section
        local stamps = chapterStructure.Layout[state.ChapterKey]
        local nextSectionSize = #stamps - (state.ChapterSection * stampsPerPage)

        if nextSectionSize > 0 then
            state.ChapterSection += 1
        else
            state.ChapterSection = 1
            state.ChapterIndex += 1
            state.ChapterKey = chapterKeys[state.ChapterIndex]

            -- ERROR: Out of bounds
            if not state.ChapterKey then
                error("Out of bounds - no more chapter keys")
            end
        end

        state.Countdown -= 1
    end

    --TODO May want to implement some logic ordering for the order stamps are displayed in.. for now, it is the order they are registered
    local finalStamps: { Stamps.Stamp } = {}
    local startIndex = 1 + ((state.ChapterSection - 1) * stampsPerPage)
    for i = startIndex, startIndex + (stampsPerPage - 1) do
        local stamp = chapterStructure.Layout[state.ChapterKey][i]
        if stamp then
            table.insert(finalStamps, stamp)
        else
            break
        end
    end

    return {
        Key = state.ChapterKey,
        Stamps = finalStamps,
    }
end

function StampUtil.getStampDataAddress(stampId: string)
    return ("Stamps.OwnedStamps.%s"):format(stampId)
end

function StampUtil.getStampBookDataDefaults()
    return {
        CoverColor = {
            Unlocked = { "Brown" },
            Selected = "Brown",
        },
        CoverPattern = {
            Unlocked = { "Voldex" },
            Selected = "Voldex",
        },
        TextColor = {
            Unlocked = { "White" },
            Selected = "White",
        },
        Seal = {
            Unlocked = { "Gold" },
            Selected = "Gold",
        },
        CoverStampIds = {},
    }
end

function StampUtil.getStampIdCmdrArgument(stampTypeArgument)
    local stampType = stampTypeArgument:GetValue()
    return {
        Type = StampUtil.getStampIdCmdrTypeName(stampType),
        Name = "stampId",
        Description = ("stampId (%s)"):format(stampType),
    }
end

function StampUtil.getStampIdCmdrTypeName(stampType: string)
    return StringUtil.toCamelCase(("%sStampId"):format(stampType))
end

-- Calculations
do
    totalStamps = 0
    for _, stampModules in pairs(ReplicatedStorage.Shared.Stamps.StampTypes:GetChildren()) do
        totalStamps += #require(stampModules)
    end
end

return StampUtil
