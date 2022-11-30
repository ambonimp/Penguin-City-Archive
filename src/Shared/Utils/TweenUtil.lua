local TweenUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage.Shared
local Binder = require(shared.Binder)
local packages = ReplicatedStorage.Packages
local Promise = require(packages.promise)

-- Creates a tween, and automatically plays it
function TweenUtil.tween(instance: Instance, tweenInfo: TweenInfo, propertyTable: { [string]: any })
    local tween = TweenService:Create(instance, tweenInfo, propertyTable)
    tween:Play()

    return tween
end

--[[
    Cancels any existing tweens binded to an instance, creates a new one, plays it and then binds it to said instance
]]
--
function TweenUtil.bind(instance: Instance, bindKey: string, tween: Tween, onCompleted: (Enum.PlaybackState) -> ()?)
    Binder.invokeBindedMethod(instance, bindKey, "Cancel")

    Binder.bind(instance, bindKey, tween)
    Binder.unbindOnBindedEvent(instance, bindKey, "Completed")

    tween.Completed:Connect(function(playbackState)
        Binder.bind(instance, bindKey)
        if onCompleted then
            onCompleted(playbackState)
        end
    end)

    tween:Play()

    return tween
end

--[[
    Returns a promise that resolves when a tween is completed
]]
function TweenUtil.promisify(instance: Instance, tweenInfo: TweenInfo, goal: { [string]: any })
    return function()
        return Promise.new(function(resolve, _, onCancel)
            local tween = TweenService:Create(instance, tweenInfo, goal)

            if onCancel(function()
                tween:Cancel()
            end) then
                return
            end

            tween.Completed:Connect(resolve)
            tween:Play()
        end)
    end
end

--[[
    Every frame, will call `callback` with an alpha value which is calculated from the tweenInfo.

    Returns an RBXScriptConnection that:
    - Will automatically disconnect when the tween is completed
    - You can disconnect at any time yourself!
]]
function TweenUtil.run(callback: (alpha: number, dt: number, prevAlpha: number?) -> nil, tweenInfo: TweenInfo)
    local startTick = tick() + tweenInfo.DelayTime
    local repeatsLeft = tweenInfo.RepeatCount

    local prevAlpha: number?
    local isReversing = false

    local connection: RBXScriptConnection
    connection = RunService.RenderStepped:Connect(function(dt)
        -- RETURN: Delay time stops us from starting yet
        local thisTick = tick()
        if thisTick < startTick then
            return
        end

        -- Calculate time
        local timeElapsed = thisTick - startTick
        local timeAlpha = math.clamp(timeElapsed / tweenInfo.Time, 0, 1)
        if isReversing then
            timeAlpha = 1 - timeAlpha
        end

        -- Times up! What do?
        if isReversing and timeAlpha == 0 or timeAlpha == 1 then
            local doReverse = isReversing == false and tweenInfo.Reverses
            if doReverse then
                isReversing = true
                startTick += tweenInfo.Time
            else
                isReversing = false

                repeatsLeft -= 1
                if repeatsLeft == -1 then
                    -- Exit
                    connection:Disconnect()
                else
                    -- Loop back
                    startTick += tweenInfo.Time
                end

                callback(timeAlpha, dt, prevAlpha)
                return
            end
        end

        -- Tween
        local tweenAlpha = TweenService:GetValue(timeAlpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
        callback(tweenAlpha, dt, prevAlpha)

        prevAlpha = tweenAlpha
    end)

    return connection
end

return TweenUtil
