local ArrayUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

type Array = { any }

--[[
    Returns the of two arrays stored in the first array(tbl1: Array). Duplicates are allowed
]]
function ArrayUtil.add(tbl1: Array, tbl2: Array): Array
    table.move(tbl2, 1, #tbl2, #tbl1 + 1, tbl1)
    return tbl1
end

function ArrayUtil.subtract(tbl: Array, subtracting: Array): Array
    for i, v in tbl do
        if table.find(subtracting, v) then
            table.remove(tbl, i)
        end
    end

    return tbl
end

function ArrayUtil.clone(tbl: Array): Array
    return table.move(tbl, 1, #tbl, 1, {})
end

--[[
    Returns the union of two arrays. Duplicates are allowed.
]]
function ArrayUtil.addToClone(tbl1: Array, tbl2: Array): Array
    return ArrayUtil.add(ArrayUtil.clone(tbl1), tbl2)
end

function ArrayUtil.flip(tbl: Array): Array
    local returning = {}

    for i = #tbl, 1, -1 do
        table.insert(returning, tbl[i])
    end

    return returning
end

--[[
    Populates an empty table with the returns of a function
    Essentially Table.create without shared values
]]
function ArrayUtil.create(length: number, getValue: (number?) -> ()): Array
    local returning = {}
    for i = 1, length do
        returning[i] = getValue(i)
    end

    return returning
end

function ArrayUtil.toDict(tbl: { any })
    local dict = {}

    for i, v in pairs(tbl) do
        dict[tostring(i)] = v
    end

    return dict
end

return ArrayUtil
