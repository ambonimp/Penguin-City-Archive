local TableUtil = {}

function TableUtil.clone(tbl)
    local clone = {}

    for i, v in tbl do
        clone[i] = typeof(v) == "table" and TableUtil.clone(v) or v
    end

    return clone
end

function TableUtil.merge(tbl1: table, tbl2: table)
    for i, v in tbl2 do
        tbl1[i] = v
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

    for k, v in tbl do
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

-- table.find doesn't work for dictionaries
function TableUtil.find(tbl: table, needle: any)
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

return TableUtil
