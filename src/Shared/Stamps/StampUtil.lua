local StampUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)

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
