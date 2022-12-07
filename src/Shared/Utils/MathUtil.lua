local MathUtil = {}

local LARGE_NUMBER_ENCODING_VERSION = 1

local internalRandom = Random.new(os.time())

--[[
    Linearly normalizes value from a range. Range must not be empty. This is the inverse of lerp.
    Example: function(20, 10, 30) returns 0.5.
]]
function MathUtil.normalize(value: number, rangeStart: number, rangeEnd: number, clamp: boolean)
    local result = (value - rangeStart) / (rangeEnd - rangeStart)
    if clamp then
        result = math.min(1.0, math.max(0.0, result))
    end
    return result
end

--[[
    Linearly map a value from one range to another. Input range must not be empty. This is the same as chaining Normalize from input range and Lerp to output range.
    Example: function(20, 10, 30, 50, 100) returns 75.
]]
function MathUtil.map(value: number, inRangeStart: number, inRangeEnd: number, outRangeStart: number, outRangeEnd: number, clamp: boolean?)
    local result = outRangeStart + (value - inRangeStart) * (outRangeEnd - outRangeStart) / (inRangeEnd - inRangeStart)
    if clamp then
        result = math.clamp(result, math.min(outRangeStart, outRangeEnd), math.max(outRangeStart, outRangeEnd))
    end
    return result
end

--[[
    Returns a linear interpolation between the given boundaries at a certain progress.
]]
function MathUtil.lerp(from: number, to: number, progress: number)
    return from + (to - from) * progress
end

---
---Basic round function
---@param value number
---
local function round(value)
    return math.floor(value + 0.5)
end

--[[
    Rounds a number according to the desired amount of decimals.

    Examples:
     - Round(184.123,  3) = 184.123
     - Round(184.123,  2) = 184.12
     - Round(184.123,  1) = 184.1
     - Round(184.123,  0) = 184
     - Round(184.123, -1) = 190
     - Round(184.123, -2) = 200
]]
function MathUtil.round(value: number, decimals: number)
    -- Sanitize
    value = value or 0
    decimals = decimals or 0

    -- Round value
    local a = 10 ^ decimals
    local result = round(value * a) / a

    -- Strip unwanted decimals
    local wereDecimalsRequested = decimals and decimals >= 1
    local areDecimalsZero = (result % math.floor(result)) <= 0.01
    if not wereDecimalsRequested or areDecimalsZero then
        result = round(result)
    end

    -- Return result
    return result
end

--[[
    Rounds a number keeping a certain amount of significant figures.
    Returns the number, then the string.

    Examples:
     - SignificantFigures(123.45,  5) = 123.45, "123.45"
     - SignificantFigures(123.45,  4) = 123.5, "123.5"
     - SignificantFigures(123.45,  3) = 123, "123"
     - SignificantFigures(123.45,  2) = 120, "120"
     - SignificantFigures(123.45,  1) = 100, "100"
     - SignificantFigures(123.45,  0) = 0, "0"
     - SignificantFigures(0.6, 2) = 0.6, "0.60"
     - SignificantFigures(7.8, 4) = 7.8, "7.800"
]]
function MathUtil.significantFigures(value: number, figures: number, integer: boolean)
    if value == 0 then
        return 0, "0"
    end

    -- Calculate number
    local exponent = figures - math.floor(math.log10(math.abs(value)))
    local rawNumber = math.round(value * 10 ^ exponent) / 10 ^ exponent
    local number = integer and math.round(rawNumber) or rawNumber

    -- Calculate string
    local str = tostring(number)
    local magnitude = math.floor(math.log10(math.abs(value)))
    if exponent >= magnitude then
        str = ("%%.%df"):format(exponent - 1):format(number)
    end

    -- Return
    return number, str
end

--[[
    Makes a weighted choice based on the given table.
    Returns `Value`
]]
function MathUtil.weightedChoice(
    tbl: {
        {
            Weight: number,
            Value: any,
        }
    },
    random: Random?
)
    local sum = 0
    for _, entry in pairs(tbl) do
        if entry.Weight < 0 then
            warn(tbl)
            error("[MathUtil.weightedChoice] Weight value cannot be less than zero. Culprit: %s")
        end
        sum = sum + entry.Weight
    end

    if sum <= 0 then
        warn(tbl)
        error(("[MathUtil.weightedChoice] The sum of all weights is not greater than 0 (%d)"):format(sum))
    end

    local rnd = MathUtil.nextNumber(0, sum, random)
    local lastEntry = nil
    for _, entry in pairs(tbl) do
        lastEntry = entry
        if rnd < entry.Weight then
            return entry.Value
        end
        rnd = rnd - entry.Weight
    end

    return lastEntry.Value
end

--[[
    Wraps a number around a limit. Useful for accessing wrapped array indexes seamlessly.

    Examples:
     - WrapAround(number: -1, limit: 5) => output: 4
     - WrapAround(number: 0, limit: 5) => output: 5
     - WrapAround(number: 1, limit: 5) => output: 1
     - WrapAround(number: 5, limit: 5) => output: 5
     - WrapAround(number: 6, limit: 5) => output: 1
     - WrapAround(number: 7, limit: 5) => output: 2
]]
function MathUtil.wrapAround(number: number, limit: number)
    return (number - 1) % limit + 1
end

--[[
    Encodes any large number supported by Lua into a database format that's smaller than 64 bits.
    12 significant figures are preserved, while the others are lost.
]]
function MathUtil.encodeLargeNumber(number: number, printDebug: boolean?)
    --[[
        FORMAT = |V|SEEE|SMMMMMMMMMMMM|
             V = Version
             S = Sign (1 for positive, 0 for negative)
             E = Exponent (3 digits)
             M = Mantissa (12 digits)

        EXAMPLE: 110731498700000000
                 1----------------- => Version: 1
                 -1---------------- => Exponent Sign: 1 (Exponent is positive)
                 --073------------- => Exponent: 73
                 -----1------------ => Mantissa Sign: 1 (Mantissa is positive)
                 ------498700000000 => Mantissa: 498700000000 (Becomes 0.498700000000)
    --]]

    -- Sanitize
    number = number or 0

    -- Extract mantissa and exponent
    local mantissa, exponent = math.frexp(number) ---@type number
    local encodedVersion = LARGE_NUMBER_ENCODING_VERSION * 1e17
    local encodedExponent = math.floor(math.abs(exponent * 1e13))
    local encodedMantissa = math.floor(math.abs(mantissa * 1e12))
    local encodedExponentSign = exponent > 0 and 1e16 or 0
    local encodedMantissaSign = mantissa > 0 and 1e12 or 0
    local encodedNumber = encodedVersion + encodedExponentSign + encodedExponent + encodedMantissaSign + encodedMantissa

    -- Debug printing
    if printDebug then
        print("\tEncoding number:", number)
        print(("\t%f -> %s"):format(mantissa, "mantissa"))
        print(("\t%f -> %s"):format(exponent, "exponent"))
        print(("\t%018.0f -> %s"):format(encodedVersion, "encodedVersion"))
        print(("\t%018.0f -> %s"):format(encodedExponentSign, "encodedExponentSign"))
        print(("\t%018.0f -> %s"):format(encodedExponent, "encodedExponent"))
        print(("\t%018.0f -> %s"):format(encodedMantissaSign, "encodedMantissaSign"))
        print(("\t%018.0f -> %s"):format(encodedMantissa, "encodedMantissa"))
        print(("\t%018.0f -> %s"):format(encodedNumber, "encodedNumber"))
    end

    return encodedNumber
end

--[[
    Decodes any large number supported by Lua from a database format that's smaller than 64 bits.
    12 significant figures are preserved, while the others are lost.
]]
function MathUtil.decodeLargeNumber(number: number, printDebug: boolean?)
    -- Decode version from number (in case the number was encoded with a version -- Otherwise this will be zero)
    local version = math.floor(number / 1e17)

    -- Current version
    if version == LARGE_NUMBER_ENCODING_VERSION then
        --[[
            FORMAT = |V|SEEE|SMMMMMMMMMMMM|
                 V = Version
                 S = Sign (1 for positive, 0 for negative)
                 E = Exponent (3 digits)
                 M = Mantissa (12 digits)
        --]]

        local exponentSign = math.floor((number / 1e16) % 1e1) == 1 and 1 or -1
        local exponent = math.floor((number / 1e13) % 1e3) * exponentSign
        local mantissaSign = math.floor((number / 1e12) % 1e1) == 1 and 1 or -1
        local mantissa = ((number % 1e12) / 1e12) * mantissaSign
        local decodedNumber = math.ldexp(mantissa, exponent)

        -- Debug printing
        if printDebug then
            print(("\tDecoding number: %018.0f"):format(number))
            print(("\t%f -> %s"):format(version, "version"))
            print(("\t%f -> %s"):format(exponentSign, "exponentSign"))
            print(("\t%f -> %s"):format(exponent, "exponent"))
            print(("\t%f -> %s"):format(mantissaSign, "mantissaSign"))
            print(("\t%f -> %s"):format(mantissa, "mantissa"))
            print(("\t%f -> %s"):format(decodedNumber, "decodedNumber"))
        end

        return decodedNumber
    end

    -- Version 0 (before versioning was implemented)
    if version == 0 then
        --[[
            FORMAT = |H|EEE|SSSS|
                 H = Fixed "1" header
                 E = 3 digits exponent
                 C = 4 significant digits
        --]]

        -- Make sure number is greater than our header
        local h = 10000000
        number = math.max(h, number)

        -- Decode
        local exponent = math.floor((number - 10000000) / 10000)
        local significant = (number - (math.floor(number / 10000) * 10000)) / 1000
        local decoded = significant * math.pow(10, exponent)

        -- Debug printing
        if printDebug then
            print(("\tDecoding number: %018.0f"):format(number))
            print(("\t%f -> %s"):format(version, "version"))
            print(("\t%f -> %s"):format(exponent, "exponent"))
            print(("\t%f -> %s"):format(significant, "significant"))
            print(("\t%f -> %s"):format(decoded, "decoded"))
        end

        return decoded
    end
end

--[[
    Returns a pseudorandom float uniformly distributed over [min, max].
]]
function MathUtil.nextNumber(min: number, max: number, random: Random?)
    return MathUtil.lerp(min, max, random and random:NextNumber() or internalRandom:NextNumber())
end

--[[
    Returns a pseudorandom float uniformly distributed over [numberRange.Min, numberRange.Max].
]]
function MathUtil.nextNumberInRange(numberRange: NumberRange)
    return MathUtil.nextNumber(numberRange.Min, numberRange.Max)
end

--[[
    Returns a boolean indicating if the given chance was met when compared with a internalRandom value. Chance must be between 0 and 1.
]]
function MathUtil.nextChance(chance: number?)
    return internalRandom:NextNumber() <= (chance or 0)
end

--[[
    Returns a pseudorandom integer uniformly distributed over [min, max].
]]
function MathUtil.nextInteger(min: number, max: number)
    return internalRandom:NextInteger(min, max)
end

--[[
    Returns the given number with a internalRandom variation applied, from a range of -1 to +1.
]]
function MathUtil.nextVariation(value: number, variation: number)
    return value + variation * MathUtil.nextNumber(-1, 1)
end

--[[
Returns a internalRandom angle in degrees from 0 to 360.
]]
function MathUtil.nextDegrees()
    return MathUtil.nextNumber(0, 360)
end

--[[
    Returns a internalRandom angle in radians from 0 to 2PI.
]]
function MathUtil.nextRadians()
    return MathUtil.nextNumber(0, math.pi * 2)
end

--[[
    Returns a pseudorandom boolean.
]]
function MathUtil.nextBoolean()
    return internalRandom:NextNumber() >= 0.5
end

--[[
    Returns a triangularly distributed internalRandom number between "min" and "max", where values close to the "around" one
    are more likely to be chosen. In the event that "around" is not between the given boundaries, the result is clamped.
    - around: The point around which the values are more likely. Defaults to the average between min and max.
]]
function MathUtil.nextTriangular(min: number, max: number, around: number)
    -- Sanitize
    if not around then
        around = (min + max) / 2
    end
    if min > max then
        local originalMin = min
        local originalMax = max
        min = originalMax
        max = originalMin
    end

    local u = internalRandom:NextNumber()
    local d = max - min
    local r = 0
    if u <= (around - min) / d then
        r = min + math.sqrt(u * d * (around - min))
    else
        r = max - math.sqrt((1 - u) * d * (max - around))
    end
    return math.clamp(r, min, max)
end

--[[
    Given a radius, will return a Vector2 of a point on the circumference of a circle of radius `radius`.
    The centre of the circle is at the origin.
    Example:
     Given a radius of 2, we could get the point (0, -2)
]]
function MathUtil.nextCircumferencePoint(radius: number)
    local rad = math.rad(MathUtil.nextDegrees())
    return Vector2.new(radius * math.sin(rad), radius * math.cos(rad))
end

--[[
    Given a radius, will return a Vector2 of a point inside a circle of radius `radius`.
    The centre of the circle is at the origin.
    Example:
     Given a radius of 2, we could get the point (0.5, -1.3)
]]
function MathUtil.nextCirclePoint(radius: number, minRadius: number)
    -- Default values
    minRadius = minRadius or 0

    local point = Vector2.new(radius, radius)
    while true do
        point = Vector2.new(MathUtil.nextInteger(-radius, radius), MathUtil.nextInteger(-radius, radius))

        local mag = point.Magnitude
        if mag <= radius and mag >= minRadius then
            break
        end
    end

    return point
end

--[[
    https://developer.roblox.com/en-us/articles/Bezier-curves

    - `v0`: Start Position
    - `v1`: Intermediate Position
    - `v2`: End Position
]]
function MathUtil.getQuadraticBezierPoint(alpha: number, v0: Vector3, v1: Vector3, v2: Vector3)
    alpha = math.clamp(alpha, 0, 1)
    return (1 - alpha) ^ 2 * v0 + 2 * (1 - alpha) * alpha * v1 + alpha ^ 2 * v2
end

--[[
    Will run num0 - num1 in % modulo.
    Useful for calculating shortest distance.
    Returned number may not be in modulo, but is the "quickest" way to get from num0 to num1 by minus.
    Example:
        print(MathUtil.subtractModulo(350, 10, 360)) -> -20
        (350 - -20) % 360 = 10
]]
function MathUtil.subtractModulo(num0: number, num1: number, modulo: number)
    local minus = (num0 - num1) % modulo
    if math.abs(minus) > modulo / 2 then
        local sign = math.sign(minus)
        minus = modulo - math.abs(minus)
        minus = minus * -sign
    end

    return minus
end

--[[
    https://stackoverflow.com/a/19287714 <3 (I did the difficult job of rewriting it in lua)

    n >= 1
]]
function MathUtil.getSquaredSpiralPosition(n: number): Vector2
    -- given n an index in the squared spiral
    -- p the sum of point in inner square
    -- a the position on the current square
    -- n = p + a

    -- Edge Cases
    n -= 2
    if n == -1 then
        return Vector2.new(0, 0)
    end

    -- compute radius: inverse arithmetic sum of 8 + 16 + 24..
    local r = math.floor((math.sqrt(n + 1) - 1) / 2) + 1
    -- compute total points on radius-1: arithmetic sum of 8+16+24..
    local p = (8 * r * (r - 1)) / 2
    -- points by face
    local en = r * 2
    -- compute de position and shift it so the first if (-r,r) but (-r+1,-r) so square can connect
    local a = (1 + n - p) % (r * 8)

    -- find the face
    local pos = { 0, 0, r }
    local faceValue = math.floor(a / (r * 2))
    if faceValue == 0 then
        pos[1] = a - r
        pos[2] = -r
    elseif faceValue == 1 then
        pos[1] = r
        pos[2] = (a % en) - r
    elseif faceValue == 2 then
        pos[1] = r - (a % en)
        pos[2] = r
    elseif faceValue == 3 then
        pos[1] = -r
        pos[2] = r - (a % en)
    end

    return Vector2.new(pos[1], pos[2])
end

--[[
    Example:

    getDigit(457, 2) -> 4, 400
    getDigit(457, 1) -> 5, 50
    getDigit(457, 0) -> 7, 7
    getDigit(457, 3) -> 0, 0
]]
function MathUtil.getDigit(n: number, exponent: number)
    local digit = 10 ^ exponent
    local digitPlus = 10 ^ (exponent + 1)
    n = n % digitPlus

    local result = math.floor(n / digit)
    return result, result * digit
end

return MathUtil
