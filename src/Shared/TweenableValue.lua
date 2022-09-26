local TweenableValue = {}

local TweenService = game:GetService("TweenService")

function TweenableValue.new(
    valueType: string,
    goal: any,
    length: (number | (old: any, new: any) -> number),
    easingStyle: Enum.EasingStyle,
    easingDirection: Enum.EasingDirection
)
    local tweenableValue = {}

    local initialValue = goal
    local tween: Tween?

    local valueInstance = Instance.new(valueType)
    valueInstance.Value = goal

    --[[
        When the value changes, so does the instance's property
    ]]
    function tweenableValue:BindToProperty(instance: Instance, property: string)
        instance[property] = valueInstance.Value
        valueInstance.Changed:Connect(function(newVal)
            instance[property] = newVal
        end)
    end

    --[[
        Cancels any ongoing tweens and tweens to new value
    ]]
    function tweenableValue:Set(newGoal: any, _length: number?)
        if newGoal == goal then
            print("OH NO")
            return
        end

        self:Stop()
        goal = newGoal

        _length = _length or if typeof(length) == "function" then length(valueInstance, goal) else length
        tween = TweenService:Create(valueInstance, TweenInfo.new(_length, easingStyle, easingDirection), { Value = goal })
        tween:Play()
    end

    function tweenableValue:Get()
        return self.Value.Value
    end

    --[[
        Sets the value to the initial value
    ]]
    function tweenableValue:Reset(_length: number?)
        self:Set(initialValue, _length)
    end

    --[[
        Pauses any ongoing tweens
    ]]
    function tweenableValue:Stop()
        if tween then
            tween:Cancel()
            tween = nil
        end
    end

    return tweenableValue
end

return TweenableValue
