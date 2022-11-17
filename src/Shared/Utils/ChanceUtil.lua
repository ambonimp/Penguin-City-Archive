local ChanceUtil = {}

local random = Random.new()

function ChanceUtil.drawFromPool<T>(pool: { [T]: number }): T
    local sum = 0
    for _, probability in pairs(pool) do
        sum += probability
    end

    local rng = random:NextNumber(0, sum)
    for pick, probability in pairs(pool) do
        if rng <= probability then
            return pick
        else
            rng -= probability
        end
    end
end

return ChanceUtil
