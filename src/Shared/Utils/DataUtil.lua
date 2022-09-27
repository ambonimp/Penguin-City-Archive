--[[
    A utility for interfacing with a table(Datastores) via addresses
    A address is just a sequence of keys seperated by a delimiter that point you to a value in a dictionary (Ex: "Home/Left/Right" or "Home.Left.Right")
    Any non-alphanumeric characters are valid delimiters except for underscores
]]

local DataUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

type Data = { [string]: (string | number | {}) }
export type Store = Data

--[[
    Generates an array of table keys(directions) from a string formatted like a address
]]
function DataUtil.keysFromAddress(address: string): { string }
    local keys = {}

    for word in string.gmatch(address, "[%w(_)]+") do
        table.insert(keys, word)
    end

    return keys
end

--[[
    Retrieves a value stored in an array
]]
function DataUtil.getFromAddress(store: Data, address: string)
    local keys = DataUtil.keysFromAddress(address)
    for i = 1, #keys do -- master directory is 1
        store = store[keys[i]]
    end

    return store
end

--[[
    Set a value in table using an array of keys point to it's new location in the table
]]
function DataUtil.setFromAddress(store: Data, keys: { string }, newValue: any)
    if #keys == 1 then
        newValue = if typeof(newValue) == "table" then TableUtil.clone(newValue) else newValue
        store[keys[1]] = newValue

        return newValue
    else -- Goes one level/key deeper
        local key = table.remove(keys, 1)
        return DataUtil.setFromAddress(store[key], keys, newValue)
    end
end

--[[
    Returns a syncKey's paramater
    syncKeys can carry paramaters if formated like so "Key_Paramater"
]]
function DataUtil.getSyncKeyParamater(syncKey)
    return string.gsub(syncKey, "%a+_", "")
end

--[[
    Returns a syncKey by seperating it from any paramaters
]]
function DataUtil.getSyncKey(syncKey)
    return string.gsub(syncKey, "_.+", "")
end

return DataUtil
