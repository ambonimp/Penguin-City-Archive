local TweenableValue = {}

local TweenService = game:GetService("TweenService")

function TweenableValue.new<T>(
    valueType: "BoolValue" | "BrickColorValue" | "CFrameValue" | "Color3Value" | "IntValue" | "NumberValue" | "ObjectValue" | "RayValue" | "StringValue" | "Vector3Value",
    initialValue: T,
    tweenInfo: TweenInfo | (old: T, new: T) -> TweenInfo
)
    local tweenableValue = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local goal: T = initialValue
    local tween: Tween?
    local tweenCreatedTime: number?
    local tweenLength: number?

    local valueInstance = Instance.new(valueType)
    valueInstance.Value = goal

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function playTween(playing: Tween)
        tween = playing

        tweenLength = tween.TweenInfo.Time
        tweenCreatedTime = os.clock()
        tween.Completed:Connect(function(playbackState)
            if playbackState == Enum.PlaybackState.Completed then
                tween = nil
            end
        end)

        playing:Play()
    end
    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    -- When the value changes, so does the instance's property
    function tweenableValue:BindToProperty(instance: Instance, property: string)
        instance[property] = valueInstance.Value
        valueInstance.Changed:Connect(function(newVal)
            instance[property] = newVal
        end)

        return tweenableValue
    end

    -- When the value changes, so does the instance's property
    function tweenableValue:BindToCalback(callback: (newValue: T, completed: number) -> ())
        valueInstance.Changed:Connect(function(newValue)
            callback(newValue, math.min(1, (os.clock() - tweenCreatedTime) / tweenLength))
        end)

        return tweenableValue
    end

    -- Cancels any ongoing tweens and tweens to new value
    function tweenableValue:Tween(newGoal: T, customTweenInfo: TweenInfo?)
        if newGoal == goal then
            return
        end

        tweenableValue:Stop()
        goal = newGoal

        customTweenInfo = customTweenInfo or (if typeof(tweenInfo) == "function" then tweenInfo(goal, valueInstance.Value) else tweenInfo)
        playTween(TweenService:Create(valueInstance, customTweenInfo, { Value = goal }))
    end

    -- Cancels any ongoing tweens and tweens to new value in time `length`
    function tweenableValue:Haste(newGoal: T, length: number)
        if newGoal == goal then
            return
        end

        tweenableValue:Stop()
        goal = newGoal

        playTween(
            TweenService:Create(valueInstance, TweenInfo.new(length, tweenInfo.EasingStyle, tweenInfo.EasingDirection), { Value = goal })
        )
    end

    function tweenableValue:Set(newGoal: T)
        tweenableValue:Stop()
        goal = newGoal

        valueInstance.Value = newGoal
    end

    function tweenableValue:Get(): T
        return valueInstance.Value
    end

    function tweenableValue:GetGoal(): T
        return goal
    end

    function tweenableValue:Reset()
        tweenableValue:Set(initialValue)
    end

    function tweenableValue:TweenReset(customTweenInfo: TweenInfo?)
        tweenableValue:Tween(initialValue, customTweenInfo)
    end

    function tweenableValue:HasteReset(length: number)
        tweenableValue:Haste(initialValue, length)
    end

    function tweenableValue:IsPlaying(): boolean
        return tween ~= nil
    end

    -- Cancels any ongoing tweens
    function tweenableValue:Stop()
        if tween then
            tween:Cancel()
            tween = nil

            tweenCreatedTime = nil
            tweenLength = nil
        end
    end

    return tweenableValue
end

return TweenableValue
