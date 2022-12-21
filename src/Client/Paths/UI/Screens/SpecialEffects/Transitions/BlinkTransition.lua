local BlinkTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraController = require(Paths.Client.CameraController)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local VoldexLoading = require(Paths.Client.UI.Screens.SpecialEffects.VoldexLoading)
local Toggle = require(Paths.Shared.Toggle)

export type Options = {
    TweenInfo: TweenInfo?,
    TweenTime: number?, -- Always overrides
    DoAlignCamera: boolean?,
    DoShowVoldexLoading: boolean?,
    Scope: string?,
}

local frame: Frame = Paths.UI:WaitForChild("SpecialEffects").Bloom
local hideShowInstances: { Instance } = ArrayUtil.merge({ frame }, frame:GetDescendants())

local isOpen = Toggle.new(false)
local isVoldexLoadingOpen = false

BlinkTransition.Defaults = { TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), Scope = "Nada" }

local function getTweenInfoFromOptions(options: Options?)
    -- Read blink options
    options = options or {}
    local tweenInfo = options.TweenInfo or BlinkTransition.Defaults.TweenInfo
    if options.TweenTime then
        tweenInfo = TweenInfo.new(options.TweenTime, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    end

    return tweenInfo
end

-- Yields
function BlinkTransition.open(options: Options?)
    -- RETURN: Already opening
    if isOpen:Get() then
        return
    end

    if isOpen:Set(true, options.Scope or BlinkTransition.Defaults.Scope) then
        local tweenInfo = getTweenInfoFromOptions(options)
        InstanceUtil.show(hideShowInstances, tweenInfo)

        if options and options.DoShowVoldexLoading then
            isVoldexLoadingOpen = true
            VoldexLoading.open(tweenInfo)
        end

        task.wait(tweenInfo.Time)
    end
end

-- Yields
function BlinkTransition.close(options: Options?)
    -- RETURN: Blink is already closed
    if not isOpen:Get() then
        return
    end
    if isOpen:Set(false, options.Scope or BlinkTransition.Defaults.Scope) then
        local tweenInfo = getTweenInfoFromOptions(options)
        InstanceUtil.hide(hideShowInstances, tweenInfo)

        if isVoldexLoadingOpen then
            VoldexLoading.close(tweenInfo)
        end

        task.wait(tweenInfo.Time)
    end
end

-- Yields
function BlinkTransition.play(onHalfPoint: (...any) -> nil, options: Options?)
    options = options or {}
    local doAlignCamera = options.DoAlignCamera and true or false

    BlinkTransition.open(options)

    onHalfPoint()
    if doAlignCamera then
        CameraController.alignCharacter()
    end

    -- Tween Out
    BlinkTransition.close(options)
end

-------------------------------------------------------------------------------
-- Logic; initial setup
-------------------------------------------------------------------------------

frame.BackgroundTransparency = 0
InstanceUtil.hide(hideShowInstances)

return BlinkTransition
