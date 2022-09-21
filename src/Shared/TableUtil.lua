local TableUtil = {}

function TableUtil.clone(t)
    local clone = {}

    for i, v in pairs(t) do
        clone[i] = typeof(v) == "table" and TableUtil.clone(v) or v
    end

    return clone
end

function TableUtil.merge(t1, t2)
    for i, v in pairs(t2) do
        t1[i] = v
    end

    return t1
end

-- table.length doesn't work for dictionaries, this does
function TableUtil.length(t)
    local length = 0
    for _, _ in pairs(t) do
        length += 1
    end

    return length
end

-- Returns a random value in a table
function TableUtil.getRandom(t)
    local selection = math.random(1, TableUtil.length(t))
    local index = 1

    for k, v in pairs(t) do
        if index == selection then
            return v, k
        else
            index += 1
        end
    end
end

-- Returns an array of dictionary keys
function TableUtil.getKeys(t)
    local returning = {}

    for k, _ in pairs(t) do
        table.insert(returning, k)
    end

    return returning
end

-- Returns an array of dictionary values
function TableUtil.getValues(t, k)
    local returning = {}

    for i, v in pairs(t) do
        returning[i] = v[k]
    end

    return returning
end

-- Fips key, value pairs. Keys become values and values become keys
function TableUtil.valuesToKeys(t, key)
    local returning = {}

    for _, v in ipairs(t) do
        if key then
            returning[v[key]] = v
        else
            returning[v] = v
        end
    end

    return returning
end

-- table.find doesn't work for dictionaries
function TableUtil.find(t, needle)
    for k, value in pairs(t) do
        if needle == value then
            return k
        end
    end

    return nil
end

-- Counts how many instances of a value (needle) appears in an table
function TableUtil.tally(t, needle)
    local count = 0
    for _, value in pairs(t) do
        if needle == value then
            count += 1
        end
    end
    return count
end

-- Returns an array of keys belonging to each instance of a value(needle) that appears appears in a table
function TableUtil.findAll(t, needle)
    local returning = {}

    for k, value in pairs(t) do
        if needle == value then
            table.insert(returning, k)
        end
    end

    return returning
end

function TableUtil.findFromProperty(t, property, identifier)
    for i, v in pairs(t) do
        if v[property] == identifier then
            return i
        end
    end
end

function TableUtil.toArray(t)
    local returning = {}

    for _, v in pairs(t) do
        table.insert(returning, v)
    end

    return returning
end

return TableUtil
