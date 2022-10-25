--[[
    Utility file for asserting types on variables
]]
local TypeUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

function TypeUtil.toString(someVariable: any, defaultValue: string?, maxLength: number?): string | nil
    local stringSomeVariable = tostring(someVariable)
    if someVariable == nil or stringSomeVariable == nil then
        return defaultValue
    end

    if maxLength then
        stringSomeVariable:sub(0, maxLength)
    end

    return stringSomeVariable
end

function TypeUtil.toNumber(someVariable: any, defaultValue: number?): number | nil
    local numberSomeVariable = tonumber(someVariable)
    if someVariable == nil or numberSomeVariable == nil then
        return defaultValue
    end

    return numberSomeVariable
end

function TypeUtil.toBoolean(someVariable: any, defaultValue: boolean?): boolean | nil
    if someVariable == true or someVariable == false then
        return someVariable
    end

    return defaultValue
end

function TypeUtil.toType(someVariable: any, expectedType: string, defaultValue: any?): any | nil
    if typeof(someVariable) == expectedType then
        return someVariable
    end

    return defaultValue
end

-- Verifies that each key,value pair in `someVariable` passes `validator`. If it fails at all, returns defaultValue
function TypeUtil.toArray(someVariable: any, validator: (someValue: any) -> boolean, defaultValue: table?): table | nil
    if typeof(someVariable) ~= "table" then
        return defaultValue
    end

    -- Check Array
    if #someVariable ~= TableUtil.length(someVariable) then
        return defaultValue
    end

    -- Verify Values
    for _, v in pairs(someVariable) do
        if not validator(v) then
            return defaultValue
        end
    end

    return someVariable
end

return TypeUtil
