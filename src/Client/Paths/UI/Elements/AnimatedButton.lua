local AnimatedButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local UDimUtil = require(Shared.Utils.UDimUtil)
local TweenUtil = require(Shared.Utils.TweenUtil)
local Elements = script.Parent
local Binder = require(Shared.Binder)
local Button = require(Elements.Button)

type ButtonObject = ImageButton | TextButton
type Animation = {
    Play: (Animation, ButtonObject) -> (),
    Revert: (Animation, ButtonObject) -> ()?,
}
type AnimationConstructor = (...any) -> Animation

local ANCHOR_POINT = Vector2.new(0.5, 0.5)
local POSITION = UDim2.fromScale(0.5, 0.5)

AnimatedButton.Animations = {} :: { [string]: AnimationConstructor }
--#region Squish Animation
do
    local DEFAULT_SCALE = UDim2.fromScale(1.2, 0.8)
    local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

    AnimatedButton.Animations.Squish = function(scale: UDim2?)
        local animation = {}

        scale = scale or DEFAULT_SCALE

        function animation:Play(button: ButtonObject)
            local initSize = Binder.bindFirst(button, "InitSize", button.Size)
            TweenUtil.bind(
                button,
                "ButtonScale",
                TweenService:Create(button, TWEEN_INFO, { Size = UDimUtil.multiplyUDim2s(initSize, scale) })
            )
        end

        function animation:Revert(button: ButtonObject)
            local initSize = Binder.bindFirst(button, "InitSize", button.Size)
            TweenUtil.bind(button, "ButtonScale", TweenService:Create(button, TWEEN_INFO, { Size = initSize }))
        end

        return animation
    end :: AnimationConstructor
end
-- #endregion
--#region Nod Animation
do
    local DEFAULT_ROTATION = 10
    local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

    AnimatedButton.Animations.Nod = function(rotation: number?)
        local animation = {}

        rotation = rotation or DEFAULT_ROTATION

        function animation:Play(button: ButtonObject)
            local initRotation = Binder.bindFirst(button, "InitRotation", button.Rotation)
            TweenUtil.bind(button, "ButtonNod", TweenService:Create(button, TWEEN_INFO, { Rotation = initRotation + rotation }))
        end

        function animation:Revert(button: ButtonObject)
            local initRotation = Binder.bindFirst(button, "InitRotation", button.Size)
            TweenUtil.bind(button, "ButtonNod", TweenService:Create(button, TWEEN_INFO, { Rotation = initRotation }))
        end

        return animation
    end :: AnimationConstructor
end
-- #endregion

AnimatedButton.Defaults = {
    PressAnimation = AnimatedButton.Animations.Squish(),
    HoverAnimation = nil,
}

function AnimatedButton.combineAnimations(animations: { Animation }): Animation
    local combinedAnimation = {}

    function combinedAnimation:Play(button: ButtonObject)
        for _, animation in pairs(animations) do
            animation:Play(button)
        end
    end

    function combinedAnimation:Revert(button: ButtonObject)
        for _, animation in pairs(animations) do
            if animation.Revert then
                animation:Revert(button)
            end
        end
    end

    return combinedAnimation
end

function AnimatedButton.new(button: typeof(Button.new(Instance.new("ImageButton"))))
    local animatedButton = button

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    local buttonObject: ImageButton | TextButton = animatedButton:GetButtonObject()

    local pressAnimation: Animation?
    local hoverAnimation: Animation?

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------
    function animatedButton:MountToUnconstrained(parent)
        local container = Instance.new("Frame")
        container.Size = buttonObject.Size
        container.Position = buttonObject.Position
        container.AnchorPoint = buttonObject.AnchorPoint
        container.ZIndex = buttonObject.ZIndex
        container.Parent = parent

        buttonObject.Size = UDim2.fromScale(1, 1)
        animatedButton:Mount(container, true)
    end

    function animatedButton:SetPressAnimation(animation: Animation?)
        pressAnimation = animation
    end

    function animatedButton:SetHoverAnimation(animation: Animation?)
        hoverAnimation = animation
    end

    function animatedButton:PlayAnimation(animation: Animation)
        animation:Play(buttonObject)
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------
    animatedButton.InternalMount:Connect(function()
        buttonObject.AnchorPoint = ANCHOR_POINT
        buttonObject.Position = POSITION
    end)

    animatedButton.InternalPress:Connect(function()
        if pressAnimation then
            pressAnimation:Play(buttonObject)
        end
    end)

    animatedButton.InternalRelease:Connect(function()
        if pressAnimation and pressAnimation.Revert then
            pressAnimation:Revert(buttonObject)
        end
    end)

    animatedButton.InternalEnter:Connect(function()
        if hoverAnimation then
            hoverAnimation:Play(buttonObject)
        end
    end)

    animatedButton.InternalLeave:Connect(function()
        if hoverAnimation and hoverAnimation.Revert then
            hoverAnimation:Revert(buttonObject)
        end
    end)

    animatedButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
    animatedButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)

    return animatedButton
end

return AnimatedButton
