-- Utility related to RichText; finding tags, removing tags, etc..
local RichTextUtil = {}

--[[
    Will look for the FIRST OCCURRENCE of tag `tagName` in `str` (optionally, from position `fromPosition`).
    
    If found, will return 4 numbers.
     1. position of start of tag.
     2. position of start of string inside of tag
     3. position of end of string inside of tag
     4. position of end of tag.
    
    Example:
     - RichtextUtil:FindTag(<i>Hello world</i>, "i", nil): 1, 4, 14, 18
]]
function RichTextUtil.findTag(str: string, tagName: string, fromPosition: number)
    -- Can we find opening of this tag?
    local tagStart0, tagStart1 = str:find("<" .. tagName, fromPosition) -- only have opening bracking as may have properties
    if not tagStart0 then
        return false
    end

    -- Need to find the closing bracket; amend tagStart1 as such (end of the starting/opening tag)
    local tagClose0 = str:find(">", tagStart0)
    if not tagClose0 then
        return false
    end
    tagStart1 = tagClose0

    -- Can we find the end of this tag?
    local tagEnd0, tagEnd1 = str:find("</" .. tagName .. ">", fromPosition)
    if not tagEnd0 then
        return false
    end

    -- ERROR: Unexpected positioning
    local isEndBeforeStart = tagEnd0 < tagStart1
    if isEndBeforeStart then
        return false
    end

    return tagStart0, tagStart1 + 1, tagEnd0 - 1, tagEnd1
end

--[[
    Will return the first tag type we find e.g., if it finds an "<i>" tag, will return "i"
]]
function RichTextUtil.findFirstTag(str: string)
    -- If no possible tags, return
    if not str:find("<") then
        return
    end

    -- Get tag positions
    local indexStart = str:find("<") -- Assume richtext
    local indexEnd = str:find(">")

    -- If no closing tag, return
    if not indexEnd or not (indexStart < indexEnd) then
        return
    end

    -- Get tag
    local tag = str:sub(indexStart + 1, indexEnd - 1)

    return tag
end

local function packTagsRecurse(str: string, list: { string })
    -- Nothing left to pack
    if str:len() == 0 then
        return
    end

    local isLookingForString = #list % 2 == 0

    local tagStart = str:find("<") -- Assume richtext
    local tagEnd = str:find(">")

    -- Get the next section of the string
    local strSection
    if isLookingForString then
        if tagStart then
            strSection = str:sub(0, tagStart - 1)
            str = str:sub(tagStart)
        else
            strSection = str
            str = ""
        end
    else
        --looking for tag
        if tagStart then
            strSection = str:sub(tagStart, tagEnd)
            str = str:sub(tagEnd + 1)
        else
            warn("Should not get here")
        end
    end

    -- Record section
    table.insert(list, strSection)

    packTagsRecurse(str, list)
end

--[[
    Will return a table of values that split up tags from strings.
    Odd indexes are strings, even values are tags.

    Example:
     - PackTags:("This <i>is</i> <b>an <i>example</i></b>")
     - { "This ", "<i>", "is", "</i>", " ", "<b>", "an ", "<i>", "example", "</i>", "", </b>" }
]]
function RichTextUtil.packTags(str: string)
    local list: { string } = {}
    packTagsRecurse(str, list)
    return list
end

--[[
    When passed a string, will return a version cleared of any richtext tags.
    A richtext tag is defined as a <, > pair.
    Useful to calculate the length of a string in how it will appear in a RichText textbox.
]]
function RichTextUtil.removeTags(str: string)
    -- No tags possible.
    if not str:find("<") then
        return str
    end

    -- Get tag positions
    local indexStart = str:find("<") -- Assume richtext
    local indexEnd = str:find(">")

    -- No closing tag.
    if not indexEnd or not (indexStart < indexEnd) then
        return str
    end

    -- Split string up
    local prefix = str:sub(0, indexStart - 1) --can assume no tags, otherwise we would;ve detected earlier tags!
    local suffix = str:sub(indexEnd + 1, str:len())

    return prefix .. RichTextUtil.removeTags(suffix)
end

--[[
    When passed a string, will return a version cleared of any richtext tags that match `tagName`.
]]
function RichTextUtil.removeSpecificTags(str: string, tagName: string)
    -- No tags possible.
    if not str:find("<") then
        return str
    end

    -- Get tag positions
    local indexStart = str:find("<") -- Assume richtext
    local indexEnd = str:find(">")

    -- No closing braclet.
    if not indexEnd or not (indexStart < indexEnd) then
        return str
    end

    -- Split string up
    local prefix = str:sub(0, indexStart - 1)
    local tag = str:sub(indexStart, indexEnd)
    local suffix = str:sub(indexEnd + 1, str:len())

    local isABadTag = string.find(tag, "<" .. tagName) or string.find(tag, "</" .. tagName)

    if isABadTag then
        return prefix .. RichTextUtil.removeSpecificTags(suffix, tagName)
    else
        return prefix .. tag .. RichTextUtil.removeSpecificTags(suffix, tagName)
    end
end

--[[
    Will return information about any tags of `tagName` in the passed string (same return type as `RichTextUtil.findTag`)

    Returns a list of tuples, where each tuple contains positions related to the tag. (see RichTextUtil:FindTag()).

    List will be in order e.g., index 1 will have a tag closer to the start of the string than at index 2
]]
function RichTextUtil.findTagsOfName(str: string, tagName: string)
    local result = {}

    -- Loop through the string, looking for `tagName`
    local contextPosition = 0
    while true do
        -- Try find positions for a `tagName`!
        local tagStart, strStart, strEnd, tagEnd = RichTextUtil.findTag(str, tagName, contextPosition)
        if not tagStart then
            break
        else
            -- Found a match; store it, then continue search further along the string.
            table.insert(result, { tagStart, strStart, strEnd, tagEnd })
            contextPosition = tagEnd + 1
        end
    end

    return result
end

--[[
    Example:
        `RichTextUtil.addTag("Hello", "i") -> "<i>Hello</i>"`

        RichTextUtil.addTag("World, "font", { "size='1'", "color='rgb(255,0,100)'" }) -> "<font size='1' color='rgb(255,0,100)'>World</font>"
]]
function RichTextUtil.addTag(str: string, tagName: string, tagContents: { string }?)
    local contentsString = ""
    if tagContents then
        contentsString = " "
        for i, tagContent in pairs(tagContents) do
            if i == #tagContents then
                contentsString = ("%s%s"):format(contentsString, tagContent)
            else
                contentsString = ("%s%s "):format(contentsString, tagContent)
            end
        end
    end

    return ("<%s%s>%s</%s>"):format(tagName, contentsString, str, tagName)
end

function RichTextUtil.getRGBTagContent(color: Color3)
    return ("color='rgb(%d, %d, %d)'"):format(color.R * 255, color.G * 255, color.B * 255)
end

return RichTextUtil
