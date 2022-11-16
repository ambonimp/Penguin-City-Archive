local Button = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Sound = require(Shared.Sound)
local Signal = require(Shared.Signal)
local Limiter = require(Shared.Limiter)
local UIElement = require(script.Parent.UIElement)
local UIUtil = require(script.Parent.Parent.Utils.UIUtil)

export type Button = typeof(Button.new(Instance.new("ImageButton")))

local idCounter = 0

function Button.fromImage(image: string)
    local imageButton = Instance.new("ImageButton")
    imageButton.Size = UDim2.fromScale(1, 1)
    imageButton.BackgroundTransparency = 1
    imageButton.Image = image

    return Button.new(imageButton)
end

function Button.new(buttonObject: ImageButton | TextButton, noAudio: boolean?)
    local button = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    noAudio = noAudio and true or false

    local isSelected = false
    local isPressed = false
    local pressedDebounce = 0
    local id = idCounter
    idCounter += 1

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    button.Pressed = Signal.new()

    button.InternalPress = Signal.new()
    button.InternalRelease = Signal.new()
    button.InternalEnter = Signal.new()
    button.InternalLeave = Signal.new()
    button.InternalMount = Signal.new() -- `{parent: Instance, hideParent: boolean?}`

    button.MountedTo = nil :: GuiObject

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function pressButton()
        button.InternalPress:Fire()

        -- Audio Feedback
        if not noAudio then
            Sound.play("ButtonPress")
        end
    end

    local function releaseButton()
        button.InternalRelease:Fire()

        -- Audio Feedback
        if not noAudio then
            Sound.play("ButtonRelease")
        end
    end

    local function mouseDown()
        -- RETURN: Already pressed?
        if isPressed then
            return
        end
        isPressed = true

        pressButton()
    end

    local function mouseUp()
        -- RETURN: Was never pressed?
        if not isPressed then
            return
        end
        isPressed = false

        releaseButton()
    end

    local function mouseEnter()
        -- RETURN: Already selected?
        if isSelected then
            return
        end
        isSelected = true

        button.InternalEnter:Fire()
    end

    local function mouseLeave()
        -- RETURN: Was never selected?
        if not isSelected then
            return
        end
        isSelected = false

        button.InternalLeave:Fire()

        -- Simulate us stopping the pressing of the button (Roblox doesn't detect MouseButton1Up when not hovering over the button)
        mouseUp()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function button:GetButtonObject()
        return buttonObject
    end

    function button:IsPressed()
        return isPressed
    end

    -- If we are hovering over the button
    function button:IsSelected()
        return isSelected
    end

    -- Internal use only.
    function button:_SetSelected(selected: boolean)
        isSelected = selected
    end

    function button:Mount(parent: GuiObject, hideParent: boolean?)
        buttonObject.Parent = parent
        buttonObject.ZIndex = parent.ZIndex

        button.MountedTo = parent

        if hideParent then
            parent.Transparency = 1
        end

        button.InternalMount:Fire(parent, hideParent)

        return self
    end

    function button:SetPressedDebounce(debounceTime: number)
        pressedDebounce = debounceTime
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------
    local maid = button:GetMaid()

    maid:GiveTask(buttonObject)
    maid:GiveTask(button.Pressed)
    maid:GiveTask(button.InternalEnter)
    maid:GiveTask(button.InternalLeave)
    maid:GiveTask(button.InternalPress)
    maid:GiveTask(button.InternalRelease)

    maid:GiveTask(buttonObject.MouseEnter:Connect(function()
        mouseEnter()
    end))
    maid:GiveTask(buttonObject.MouseLeave:Connect(function()
        mouseLeave()
    end))
    maid:GiveTask(buttonObject.MouseButton1Down:Connect(function()
        mouseDown()
    end))
    maid:GiveTask(buttonObject.MouseButton1Up:Connect(function()
        -- Check before firing, as edge cases can exist (see mouseLeave())
        if isPressed then
            local isFree = Limiter.debounce("Button", id, pressedDebounce)
            if isFree then
                button.Pressed:Fire()
            end
        end

        mouseUp()
    end))

    return button
end

return Button
