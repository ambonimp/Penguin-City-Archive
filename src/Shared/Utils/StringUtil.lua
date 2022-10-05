local StringUtil = {}

local MAX_TUPLE = 7997

--[[
    Formats a number with commas and dots. (e.g. 1234567 -> 1,234,567)
]]
function StringUtil.commaValue(n: number)
    if n == math.huge then
        return "Infinite"
    end

    -- credit http://richard.warburton.it
    local left, num, right = string.match(tostring(n), "^([^%d]*%d)(%d*)(.-)$")
    return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

--[[
    Parses the given string and produces a friendly version of it, stripping underscores and properly capitalizing words.
]]
function StringUtil.getFriendlyString(str: string)
    local result = ""

    if str then
        str = str:lower()
        local words = str:split("_")

        for i, word in ipairs(words) do
            local len = word:len()
            if len > 0 then
                local firstLetter = word:sub(1, 1):upper()
                result = result .. firstLetter

                if len > 1 then
                    local rest = word:sub(2, len)
                    result = result .. rest
                end

                if i < #words then
                    result = result .. " "
                end
            end
        end
    end

    return result
end

--[[
    Splits a string according to the separator and returns a table with the results.
    - separator: Single character to be used as separator. If nil, any whitespace is used.
    - limit: Amount of matches to group. Defaults to infinite.
]]
function StringUtil.split(input: string, separator: string, limit: number)
    separator = separator or "%s"
    limit = limit or -1
    local t = {}
    local i = 1
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        t[i] = str
        i = i + 1
        if limit >= 0 and i > limit then
            break
        end
    end
    return t
end

--[[
    Escapes a string from pattern characters, prefixing any special pattern characters with a %.
]]
function StringUtil.escape(str: string)
    local escaped = str:gsub("([%.%$%^%(%)%[%]%+%-%*%?%%])", "%%%1")
    return escaped
end

--[[
    Trims whitespace from the start and end of the string.
]]
function StringUtil.trim(str: string)
    return str:match("^%s*(.-)%s*$")
end

--[[
    Trims whitespace from the start of the string.
]]
function StringUtil.trimStart(str: string)
    return str:match("^%s*(.+)")
end

--[[
    Trims whitespace from the end of the string.
]]
function StringUtil.trimEnd(str: string)
    return str:match("(.-)%s*$")
end

--[[
    Replaces all whitespace with a single space.
]]
function StringUtil.removeExcessWhitespace(str: string)
    return str:gsub("%s+", " ")
end

--[[
    Removes all whitespace from a string.
]]
function StringUtil.removeWhitespace(str: string)
    return str:gsub("%s+", "")
end

--[[
    Checks if a string starts with a certain string.
]]
function StringUtil.startsWith(str: string, starts: string)
    return str:match("^" .. StringUtil.escape(starts)) ~= nil
end

--[[
    Checks if a string ends with a certain string.
]]
function StringUtil.endsWith(str: string, ends: string)
    return str:match(StringUtil.escape(ends) .. "$") ~= nil
end

--[[
    Checks if a string contains another string.
]]
function StringUtil.contains(str: string, contains: string)
    return str:find(contains) ~= nil
end

function StringUtil.chopStart(str: string, start: string)
    local strStart = str:sub(1, start:len())
    if strStart == start then
        return str:sub(start:len() + 1)
    end

    return nil
end

--[[
    Returns a table of all the characters in the string, in the same order and including duplicates.
]]
function StringUtil.toCharArray(str: string)
    local len = #str
    local chars: { string } = table.create(len)
    for i = 1, len do
        chars[i] = str:sub(i, 1)
    end
    return chars
end

--[[
    Returns a table of all the bytes of each character in the string.
]]
function StringUtil.toByteArray(str: string)
    local len = #str
    if len == 0 then
        return {}
    end
    if len <= MAX_TUPLE then
        return table.pack(str:byte(1, #str))
    end
    local bytes: { number } = table.create(len)
    for i = 1, len do
        bytes[i] = str:sub(i, 1):byte()
    end
    return bytes
end

--[[
    Transforms an array of bytes into a string
]]
function StringUtil.byteArrayToString(bytes: { number })
    local size = #bytes
    if size <= MAX_TUPLE then
        return string.char(table.unpack(bytes))
    end
    local numChunks = math.ceil(size / MAX_TUPLE)
    local stringBuild = table.create(numChunks)
    for i = 1, numChunks do
        local chunk = string.char(table.unpack(bytes, ((i - 1) * MAX_TUPLE) + 1, math.min(size, ((i - 1) * MAX_TUPLE) + MAX_TUPLE)))
        stringBuild[i] = chunk
    end
    return table.concat(stringBuild, "")
end

--[[
    Checks if two strings are equal, but ignores their case.
]]
function StringUtil.equalsIgnoreCase(str1: string, str2: string)
    return (str1:lower() == str2:lower())
end

--[[
    Returns a string in camelCase.
]]
function StringUtil.toCamelCase(str: string)
    str = str:gsub("[%-_]+([^%-_])", function(s)
        return s:upper()
    end)
    return str:sub(1, 1):lower() .. str:sub(2)
end

--[[
    Returns a string in PascalCase.
]]
function StringUtil.toPascalCase(str: string)
    str = StringUtil.toCamelCase(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

--[[
    Returns a string in snake_case or SNAKE_CASE.
]]
function StringUtil.toSnakeCase(str: string, uppercase: boolean)
    str = str:gsub("[%-_]+", "_"):gsub("([^%u%-_])(%u)", function(s1, s2)
        return s1 .. "_" .. s2:lower()
    end)
    if uppercase then
        str = str:upper()
    else
        str = str:lower()
    end
    return str
end

--[[
    Returns a string in kebab-case or KEBAB-CASE
]]
function StringUtil.toKebabCase(str: string, uppercase: boolean)
    str = str:gsub("[%-_]+", "-"):gsub("([^%u%-_])(%u)", function(s1, s2)
        return s1 .. "-" .. s2:lower()
    end)
    if uppercase then
        str = str:upper()
    else
        str = str:lower()
    end
    return str
end

--[[
    Converts string to uppercase.
    - Does not break richtext like string.upper() does
]]
function StringUtil.upper(str: string)
    -- If no possible tags, perform upper.
    if not str:find("<") then
        return str:upper()
    end

    -- Get tag positions
    local indexStart = str:find("<") -- Assume richtext
    local indexEnd = str:find(">")

    -- If no closing tag, perfom upper.
    if not indexEnd or not (indexStart < indexEnd) then
        return str:upper()
    end

    -- Split string up so we can try upper either side of the tag
    local prefix = str:sub(0, indexStart - 1)
    local tag = str:sub(indexStart, indexEnd)
    local suffix = str:sub(indexEnd + 1, str:len())

    return prefix .. tag .. StringUtil.upper(suffix)
end

--[[
    Takes a list of words and returns a readable string in English. e.g. "Apples, Bananas, and Cats".
]]
function StringUtil.listWords(words: { string })
    -- Calculate variables
    local result = ""
    local wordCount = #words
    local useCommas = wordCount > 2
    local commaStr = useCommas and "," or ""

    -- Concat words
    for i = 1, wordCount do
        local word = words[i]
        local isFirst = i == 1
        local isLast = i == wordCount
        if isFirst then
            result = word
        elseif isLast then
            result = ("%s%s and %s"):format(result, commaStr, word)
        else
            result = ("%s%s %s"):format(result, commaStr, word)
        end
    end

    -- Return result
    return result
end

return StringUtil
