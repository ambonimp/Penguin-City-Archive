local Lerp = {}

function Lerp.new<T>(value: T, speed: T?, onUpdate: (T) -> ()?)
    local lerp = {}

    local initialValue = value

    local function alert()
        if onUpdate then
            onUpdate(value)
        end
    end

    function lerp:Set(new: T): T
        value = new

        alert()
        return value
    end

    function lerp:Get(): T
        return value
    end

    function lerp:Reset(): T
        value = initialValue

        alert()
        return value
    end

    function lerp:UpdateConstant(target: T): T
        local delta = target - value
        value += math.sign(delta) * math.min(math.abs(delta), speed)

        alert()
        return value
    end

    function lerp:UpdateVariable(target: T, dt: T): T
        value += (target - value) * dt
        alert()
        return value
    end

    return lerp
end

return Lerp
