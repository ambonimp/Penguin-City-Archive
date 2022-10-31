local Lerp = {}

function Lerp.new<T>(position: T, speed: T?)
    local lerp = {}

    function lerp:Set(new: T)
        position = new
    end

    function lerp:Get(): T
        return position
    end

    function lerp:UpdateConstant(target: T): T
        local delta = target - position
        position += math.sign(delta) * math.min(math.abs(delta), speed)

        return position
    end

    function lerp:UpdateOnStepped(target: T, dt: T): T
        position += (target - position) * dt
        return position
    end

    return lerp
end

return Lerp
