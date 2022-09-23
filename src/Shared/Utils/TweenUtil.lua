local TweenUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage.Modules
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

return TweenUtil
