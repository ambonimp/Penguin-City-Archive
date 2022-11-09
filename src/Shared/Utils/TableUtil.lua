local TableUtil = {}

function TableUtil.deepClone(tbl: table)
    local clone = {}

    for i, v in pairs(tbl) do
        clone[i] = typeof(v) == "table" and TableUtil.deepClone(v) or v
    end

    return clone
end

function TableUtil.shallowClone(tbl: table)
    local clone = {}
    for k, v in pairs(tbl) do
        clone[k] = v
    end
    return clone
end

function TableUtil.merge(tbl1: table, tbl2: table?)
    if tbl2 then
        for i, v in tbl2 do
            tbl1[i] = v
        end
    end

    return tbl1
end

-- table.length doesn't work for dictionaries, this does
function TableUtil.length(tbl: table)
    local length = 0
    for _, _ in tbl do
        length += 1
    end

    return length
end

-- Returns a random value, key pair in a table
function TableUtil.getRandom(tbl: table)
    local selection = math.random(1, TableUtil.length(tbl))
    local index = 1

    for k, v in pairs(tbl) do
        if index == selection then
            return v, k
        else
            index += 1
        end
    end
end

-- Returns an array of dictionary keys
function TableUtil.getKeys(tbl: table)
    local returning = {}

    for k, _ in tbl do
        table.insert(returning, k)
    end

    return returning
end

-- Returns an array of dictionary values
function TableUtil.getValues(tbl: table, k: any)
    local returning = {}

    for i, v in tbl do
        returning[i] = v[k]
    end

    return returning
end

-- Fips key, value . Keys become values and values become keys
function TableUtil.valuesToKeys(tbl: table, key: any)
    local returning = {}

    for _, v in tbl do
        if key then
            returning[v[key]] = v
        else
            returning[v] = v
        end
    end

    return returning
end

-- table.find doesn't work for dictionaries. Returns the key
function TableUtil.find(tbl: table, needle: any): any | nil
    for k, value in tbl do
        if needle == value then
            return k
        end
    end

    return nil
end

-- Counts how many instances of a value (needle: any) appears in an table
function TableUtil.tally(tbl: table, needle: any)
    local count = 0
    for _, value in tbl do
        if needle == value then
            count += 1
        end
    end
    return count
end

-- Returns an array of keys belonging to each instance of a value(needle: any) that appears appears in a table
function TableUtil.findAll(tbl: table, needle: any)
    local returning = {}

    for k, value in tbl do
        if needle == value then
            table.insert(returning, k)
        end
    end

    return returning
end

function TableUtil.findFromProperty(tbl: table, property: string, identifier: any)
    for i, v in tbl do
        if v[property] == identifier then
            return i
        end
    end
end

function TableUtil.toArray(tbl: table)
    local returning = {}

    for _, v in tbl do
        table.insert(returning, v)
    end

    return returning
end

function TableUtil.isEmpty(tbl: table)
    for _, _ in tbl do
        return false
    end

    return true
end

function TableUtil.sumValues(tbl: { [any]: number })
    local sum = 0
    for _, num in pairs(tbl) do
        sum += num
    end

    return sum
end

function TableUtil.isArray(tbl: table)
    if #tbl == TableUtil.length(tbl) then
        return true
    end

    return false
end

-- Checks that two tables share the same values
function TableUtil.shallowEquals(tbl1: table?, tbl2: table?)
    if not tbl1 or not tbl2 then
        return false
    end

    for _, v in tbl1 do
        if not TableUtil.find(tbl2, v) then
            return false
        end
    end

    for _, v in tbl2 do
        if not TableUtil.find(tbl1, v) then
            return false
        end
    end

    return true
end

--[[
    If `maxOccurences` not defined, will stop after removing one instance of `value`
]]
function TableUtil.remove(tbl: table, value: any, maxOccurences: number?)
    maxOccurences = maxOccurences or 1

    if TableUtil.isArray(tbl) then
        while maxOccurences > 0 do
            local index = table.find(tbl, value)
            if index then
                table.remove(tbl, index)
                maxOccurences -= 1
            else
                break
            end
        end
    else
        for key, someValue in pairs(tbl) do
            if someValue == value then
                tbl[key] = nil
                maxOccurences -= 1
                if maxOccurences >= 0 then
                    break
                end
            end
        end
    end
end

function TableUtil.mapKeys(tbl: table, map: (key: any) -> (any))
    local mappedTbl = {}
    for key, value in pairs(tbl) do
        mappedTbl[map(key)] = value
    end

    return mappedTbl
end

return TableUtil
