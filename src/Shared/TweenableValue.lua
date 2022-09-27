local TweenableValue = {}

local TweenService = game:GetService("TweenService")

function TweenableValue.new<T>(valueType: string, goal: T, tweenInfo: TweenInfo | (old: T, new: T) -> TweenInfo)
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
    function tweenableValue:Set(newGoal: T, _tweenInfo: TweenInfo?)
        if newGoal == goal then
            return
        end

        tweenableValue:Stop()
        goal = newGoal

        _tweenInfo = _tweenInfo or (if typeof(tweenInfo) == "function" then tweenInfo(goal, valueInstance.Value) else tweenInfo)
        tween = TweenService:Create(valueInstance, _tweenInfo, { Value = goal })
        tween:Play()
    end

    function tweenableValue:Get(): T
        return tweenableValue.Value.Value
    end

    function tweenableValue:GetGoal(): T
        return goal
    end

    --[[
        Sets the value to the initial value
    ]]
    function tweenableValue:Reset(_tweenInfo: TweenInfo?)
        tweenableValue:Set(initialValue, _tweenInfo)
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
