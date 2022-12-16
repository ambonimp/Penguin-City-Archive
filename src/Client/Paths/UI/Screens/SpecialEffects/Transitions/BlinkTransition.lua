local BlinkTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraController = require(Paths.Client.CameraController)

export type Options = {
    TweenInfo: TweenInfo?,
    TweenTime: number?, -- Always overrides
    DoAlignCamera: boolean?,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local frame = Paths.UI:WaitForChild("SpecialEffects").Bloom
local isOpen: boolean
local tween: Tween?

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
BlinkTransition.TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getTweenInfo(options: Options?)
    -- Read blink options
    options = options or {}
    local tweenInfo = options.TweenInfo or BlinkTransition.TWEEN_INFO
    if options.TweenTime then
        tweenInfo = TweenInfo.new(options.TweenTime, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    end

    return tweenInfo
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function BlinkTransition.open(options: Options?)
    -- RETURN: Already opening
    if isOpen then
        if tween then
            tween.Completed:Wait()
        end

        return
    end

    if tween then
        tween:Cancel()
    end

    isOpen = true
    tween = TweenService:Create(frame, getTweenInfo(options), { BackgroundTransparency = 0 })
    tween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            tween = nil
        end
    end)

    tween:Play()
    tween.Completed:Wait()
end

function BlinkTransition.close(options: Options?)
    -- RETURN: Blink is already closed
    if not isOpen then
        if tween then
            tween.Completed:Wait()
        end
        return
    end

    if tween then
        tween:Cancel()
    end

    isOpen = false
    tween = TweenService:Create(frame, getTweenInfo(options), { BackgroundTransparency = 1 })
    tween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            tween = nil
        end
    end)
    tween:Play()
    tween.Completed:Wait()
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

return BlinkTransition
