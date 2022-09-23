--[[
    Utility file for asserting types on variables
]]
local TypeUtil = {}

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

function TypeUtil.toType(someVariable: any, expectedType: string, defaultValue: any): any | nil
    if typeof(someVariable) == expectedType then
        return someVariable
    end

    return defaultValue
end

return TypeUtil
