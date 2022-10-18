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
type ButtonAnimation = {
    Play: (ButtonAnimation, ButtonObject) -> (),
    Revert: (ButtonAnimation, ButtonObject) -> ()?,
}
type AnimationConstructor = (...any) -> ButtonAnimation

local ANCHOR_POINT = Vector2.new(0.5, 0.5)
local POSITION = UDim2.fromScale(0.5, 0.5)

AnimatedButton.Animations = {} :: { [string]: AnimationConstructor }
--#region Squish Animation
do
    local DEFAULT_SCALE = UDim2.fromScale(1.2, 0.8)
    local DEFUALT_LENGTH = 0.07
    local EASING_STYLE = Enum.EasingStyle.Back

    AnimatedButton.Animations.Squish = function(scale: UDim2?, length: number?)
        local animation = {}

        scale = scale or DEFAULT_SCALE
        length = length or DEFUALT_LENGTH

        local infoIn = TweenInfo.new(length, EASING_STYLE, Enum.EasingDirection.Out)
        local infoOut = TweenInfo.new(length, EASING_STYLE, Enum.EasingDirection.In)

        function animation:Play(button: ButtonObject)
            local initSize = Binder.bindFirst(button, "InitSize", button.Size)
            TweenUtil.bind(button, "ButtonScale", TweenService:Create(button, infoIn, { Size = UDimUtil.multiplyUDim2s(initSize, scale) }))
        end

        function animation:Revert(button: ButtonObject)
            local initSize = Binder.bindFirst(button, "InitSize", button.Size)
            TweenUtil.bind(button, "ButtonScale", TweenService:Create(button, infoOut, { Size = initSize }))
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

function AnimatedButton.combineAnimations(animations: { ButtonAnimation }): ButtonAnimation
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

function AnimatedButton.new(buttonObject: ButtonObject)
    return AnimatedButton.fromButton(Button.new(buttonObject))
end

function AnimatedButton.fromButton(button: typeof(Button.new(Instance.new("ImageButton"))))
    local animatedButton = button

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    local buttonObject: ImageButton | TextButton = animatedButton:GetButtonObject()

    local pressAnimation: ButtonAnimation?
    local hoverAnimation: ButtonAnimation?

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------
    function animatedButton:MountToUnconstrained(parent): Frame
        local container = Instance.new("Frame")
        container.Name = buttonObject.Name
        container.Size = buttonObject.Size
        container.SizeConstraint = buttonObject.SizeConstraint
        container.Position = buttonObject.Position
        container.AnchorPoint = buttonObject.AnchorPoint
        container.ZIndex = buttonObject.ZIndex
        container.LayoutOrder = buttonObject.LayoutOrder
        container.Parent = parent

        buttonObject.Size = UDim2.fromScale(1, 1)
        buttonObject.Name = "Button"
        animatedButton:Mount(container, true)

        return container
    end

    function animatedButton:SetPressAnimation(animation: ButtonAnimation?)
        pressAnimation = animation
    end

    function animatedButton:SetHoverAnimation(animation: ButtonAnimation?)
        hoverAnimation = animation
    end

    function animatedButton:PlayAnimation(animation: ButtonAnimation)
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
