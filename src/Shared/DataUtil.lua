local DataUtil = {}

local TableUtil = require(script.Parent.TableUtil)

-- Splits a string or path and generates, all non-alphanumeric characters are delimiters except for underscores
function DataUtil.keysFromPath(path)
    local keys = {}

    for word in string.gmatch(path, "[%w(_)]+") do
        table.insert(keys, word)
    end

    return keys
end

-- Get a value in table using an array of keys
function DataUtil.getFromPath(indexed, path)
    local keys = DataUtil.keysFromPath(path)
    for i = 1, #keys do -- master directory is 1
        indexed = indexed[keys[i]]
    end

    return indexed
end

-- Set a value in table using an array of keys
function DataUtil.setFromPath(indexed, keys, newValue)
    if #keys == 1 then
        newValue = typeof(newValue) == "table" and TableUtil.clone(newValue) or newValue
        indexed[keys[1]] = newValue

        return newValue
    else -- Goes one level/key deeper
        local key = table.remove(keys, 1)
        return DataUtil.setFromPath(indexed[key], keys, newValue)
    end
end

-- Data changed event names can have hold commands if you format them like so "EventName_Paramater
-- Returns the paramater
function DataUtil.getEventId(event)
    return string.gsub(event, "%a+_", "")
end

-- Get the event name itself
function DataUtil.getEvent(event)
    return string.gsub(event, "_.+", "")
end

return DataUtil
