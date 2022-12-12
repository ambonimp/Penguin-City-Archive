local Shake = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenableValue = require(ReplicatedStorage.Shared.TweenableValue)

type NumVect = number | Vector3

Shake.Defaults = {
    Speed = 10,
    Magnitude = 1.5,
    RotationalMagnitude = 0.8,
    DecaySpeed = 3,
    BuildTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
}

function Shake.new(speed: NumVect?, magnitude: NumVect?, rotationalMagnitude: NumVect?, decaySpeed: number?, buildTweenInfo: TweenInfo?)
    local shake = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    speed = speed or Shake.Defaults.Speed
    magnitude = magnitude or Shake.Defaults.Magnitude
    rotationalMagnitude = rotationalMagnitude or Shake.Defaults.RotationalMagnitude
    decaySpeed = decaySpeed or Shake.Defaults.DecaySpeed
    buildTweenInfo = buildTweenInfo or Shake.Defaults.BuildTweenInfo

    local et = 0
    local factor = TweenableValue.new("NumberValue", 0, buildTweenInfo)
    local totalOffset: CFrame = CFrame.new()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function getPerlinValue(id: number)
        return math.clamp(math.noise(id, et, 10), -1, 1)
    end
    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function shake:Update(dt: number): CFrame
        local offset: CFrame
        local factorValue = factor:Get()
        if factorValue ~= 0 then
            et += dt * math.pow(factorValue, 1 / 2) * speed

            -- Bind movement to the desired range
            local positionalOffset = CFrame.new(Vector3.new(getPerlinValue(1), getPerlinValue(50), 0) * magnitude * factorValue)
            local rotationalOffset = CFrame.fromEulerAnglesXYZ(
                math.rad(positionalOffset.X * rotationalMagnitude),
                math.rad(positionalOffset.X * rotationalMagnitude),
                math.rad(positionalOffset.Y * rotationalMagnitude)
            )

            offset = positionalOffset * rotationalOffset
            totalOffset *= offset

            if not factor:IsPlaying() then
                factor:Set(math.max(0, factorValue - dt * decaySpeed))
            end
        else
            -- Reset camera to original state
            local newTotalOffset = totalOffset:Lerp(CFrame.new(), dt * 1.5)
            offset = totalOffset:ToObjectSpace(newTotalOffset)
            totalOffset = newTotalOffset
        end

        return offset
    end

    function shake:Impulse(factorGoal: number)
        factor:Haste(factorGoal, buildTweenInfo.Time * factorGoal)
    end

    function shake:Reset()
        factor:Reset()
    end

    return shake
end

return Shake
