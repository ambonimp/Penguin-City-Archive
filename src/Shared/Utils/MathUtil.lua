local MathUtil = {}

local TableUtil = require(script.Parent.TableUtil)

local internalRandom = Random.new()

-- Pass this function a table where values are weights attributed to each key.
-- Feel free to pass your own Random object to help select a random key based on weights
function MathUtil.selectKeyFromValueWeights(weightTable: { [any]: number }, random: Random?)
    random = random or internalRandom

    -- ERROR: Is empty!
    if TableUtil.isEmpty(weightTable) then
        error("weightTable is empty!")
    end

    local totalWeight = 0
    for key, weight in pairs(weightTable) do
        -- ERROR: Negative weight
        if weight < 0 then
            error(("Key %q has a negative weight! (%s)"):format(tostring(key), weight))
        end

        totalWeight += weight
    end

    local rollingStopNumber = random:NextNumber(0, totalWeight)
    for key, weight in pairs(weightTable) do
        if weight < rollingStopNumber then
            return key
        end

        rollingStopNumber -= weight
    end

    warn("Somehow cycled through whole weight table.. returning a random entry")
    for key, _weight in pairs(weightTable) do
        return key
    end
end

return MathUtil
