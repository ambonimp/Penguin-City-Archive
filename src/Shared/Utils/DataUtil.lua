--[[
    A utility for interfacing with a table(Datastores) via addresses
    A address is just a sequence of keys seperated by a delimiter that point you to a value in a dictionary (Ex: "Home/Left/Right" or "Home.Left.Right")
    Any non-alphanumeric characters are valid delimiters except for underscores
]]

local DataUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

--local Output = require(ReplicatedStorage.Shared.Output)

export type Data = string | number | {}
export type Store = { [string]: (string | number | {}) }

--[[
    Generates an array of table keys(directions) from a string formatted like a address
]]
function DataUtil.keysFromAddress(address: string): { string }
    local keys = {}

    for word in string.gmatch(address, "[%w(_)]+") do
        table.insert(keys, word)
    end
    -- Output.debug("keysFromAddress", address, keys)

    return keys
end

--[[
    Retrieves a value stored in an array
]]
function DataUtil.getFromAddress(store: Store, address: string): Data
    local keys = DataUtil.keysFromAddress(address)
    local childStore = store
    for i = 1, #keys do -- master directory is 1
        if childStore then
            childStore = childStore[keys[i]]
        end
    end

    -- Output.debug("getFromAddress", address, keys, store, childStore)

    return childStore
end

local function setFromKeys(
    fullAddress: string,
    parentKeys: { string },
    parentStore: Store?,
    storeKeyInParent: string?,
    store: Store,
    keys: { string },
    newValue: any
)
    -- Output.debug("setFromKeys", fullAddress, parentKeys, parentStore, storeKeyInParent, store, keys, newValue)

    -- Current `store` is the table we need
    if #keys == 1 then
        local key = keys[1]

        if typeof(newValue) == "table" then
            newValue = TableUtil.deepClone(newValue)
        end

        -- Clearing `key` from `store`
        if store and newValue == nil then
            store[key] = nil

            -- If `store` is now empty, remove it from `parentStore`
            if parentStore and TableUtil.isEmpty(store) then
                parentStore[storeKeyInParent] = nil
            end

            return
        end

        -- Update `key` to `newValue`
        store[key] = newValue
        return
    end

    -- Traverse one level/key deeper
    local key = table.remove(keys, 1)
    table.insert(parentKeys, key)
    if typeof(store[key]) ~= "table" then
        if store[key] == nil then
            store[key] = {}
        else
            error(
                ("Cannot insert value %q at address %s; value at address %s is %q (not a table!)"):format(
                    tostring(newValue),
                    fullAddress,
                    table.concat(parentKeys, "."),
                    tostring(store[key])
                )
            )
        end
    end
    setFromKeys(fullAddress, parentKeys, store, key, store[key], keys, newValue)
end

--[[
    Set a value in table using an array of keys point to it's new location in the table
]]
function DataUtil.setFromAddress(store: Store, address: string, newValue: any)
    -- Output.debug("setFromAddress", address, newValue)

    -- ERROR: No keys from address
    local keys = DataUtil.keysFromAddress(address)
    if not (keys and #keys > 0) then
        error(("Bad address %q; could not get keysFromAddress"):format(address))
    end

    setFromKeys(address, {}, nil, nil, store, keys, newValue)

    -- Output.debug("setFromAddress", ("FINAL STORE %s -> %q"):format(address, tostring(newValue)), store)
end

--[[
    Returns a syncKey's paramater
    syncKeys can carry paramaters if formated like so "Key_Paramater"
]]
function DataUtil.getSyncKeyParamater(syncKey)
    local parameter = string.gsub(syncKey, "%a+_", "")
    -- Output.debug("getSyncKeyParamater", syncKey, parameter)

    return parameter
end

--[[
    Returns a syncKey by seperating it from any paramaters
]]
function DataUtil.getSyncKey(syncKey)
    local noParameters = string.gsub(syncKey, "_.+", "")
    -- Output.debug("getSyncKey", syncKey, noParameters)

    return noParameters
end

--[[
    Turns an number key(string) into an index (number)
]]
function DataUtil.readAsArray(store: Store): { [string | number]: Data }
    local returning = {}

    for k, v in pairs(store) do
        k = tonumber(k) or k
        returning[k] = if typeof(v) == "table" then DataUtil.readAsArray(v) else v
    end

    return returning
end

function DataUtil.serializeValue<T>(value: T): string
    local valueType = typeof(value)
    if valueType == "Color3" or "Vector3" then
        return tostring(valueType)
    end
end

function DataUtil.deserializeValue<T>(serializedValue: string, valueType: T): T
    if valueType == Color3 then
        return Color3.new(table.unpack(string.split(serializedValue, ", ")))
    elseif valueType == Vector3 then
        return Vector3.new(table.unpack(string.split(serializedValue, ", ")))
    end
end

return DataUtil
