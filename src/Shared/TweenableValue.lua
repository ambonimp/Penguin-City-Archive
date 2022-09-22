local TweenService = game:GetService("TweenService")

local Class = {}
Class.__index = Class

function Class.new(
    valueType: string,
    goal: any,
    length: (number | (old: any, new: any) -> number),
    easingStyle: Enum.EasingStyle,
    easingDirection: Enum.EasingDirection
)
    local self = {}

    local initialValue = goal
    local tween

    local valueInstance = Instance.new(valueType)
    valueInstance.Value = goal

    --[[
        When the value changes, so does the instance's property
    ]]
    function self:BindToProperty(instance: Instance, property: string)
        instance[property] = valueInstance.Value
        valueInstance.Changed:Connect(function(newVal)
            instance[property] = newVal
        end)
    end

    --[[
        Cancels any ongoing tweens and tweens to new value
    ]]
    function self:Set(newGoal: any, _length: number?)
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

    function self:Get()
        return self.Value.Value
    end

    --[[
        Sets the value to the initial value
    ]]
    function self:Reset(_length: number?)
        self:Set(initialValue, _length)
    end

    --[[
        Pauses any ongoing tweens
    ]]
    function self:Stop()
        if tween then
            tween:Cancel()
            tween = nil
        end
    end

    return self
end

return Class
