local VolumeWindow = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local TitledWindow = require(Paths.Client.UI.Elements.TitledWindow)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ProductController = require(Paths.Client.ProductController)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local Maid = require(Paths.Shared.Maid)
local Signal = require(Paths.Shared.Signal)
local InputController = require(Paths.Client.Input.InputController)
local SettingsController = require(Paths.Client.Settings.SettingsController)

local SLIDER_DECIMALS = 2

local function createSettingLine(maid: typeof(Maid.new()), name: string)
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = name
    settingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    settingFrame.BackgroundTransparency = 1
    settingFrame.Size = UDim2.fromScale(1, 0.2)
    maid:GiveTask(settingFrame)

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "textLabel"
    textLabel.Font = UIConstants.Font
    textLabel.Text = name
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 60
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(0.5, 1)

    local uIStroke = Instance.new("UIStroke")
    uIStroke.Name = "uIStroke"
    uIStroke.Color = Color3.fromRGB(38, 71, 118)
    uIStroke.Thickness = 2
    uIStroke.Parent = textLabel

    textLabel.Parent = settingFrame

    local uIListLayout1 = Instance.new("UIListLayout")
    uIListLayout1.Name = "uIListLayout1"
    uIListLayout1.Padding = UDim.new(0, 10)
    uIListLayout1.FillDirection = Enum.FillDirection.Horizontal
    uIListLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
    uIListLayout1.Parent = settingFrame

    local interaction = Instance.new("Frame")
    interaction.Name = "interaction"
    interaction.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    interaction.BackgroundTransparency = 1
    interaction.Size = UDim2.fromScale(0.5, 1)
    interaction.Parent = settingFrame

    return settingFrame
end

--[[
    `startValue e [0, 1]`

    Returns a Signal that is fired with a new value whenever value is updated
]]
local function createInteractionSlider(maid: typeof(Maid.new()), parent: GuiObject, startValue: number)
    --#region Create UI
    local slider = Instance.new("Frame")
    slider.Name = "slider"
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.fromScale(1, 1)
    slider.Parent = parent
    maid:GiveTask(slider)

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 5)
    uIPadding.PaddingLeft = UDim.new(0, 100)
    uIPadding.PaddingRight = UDim.new(0, 100)
    uIPadding.PaddingTop = UDim.new(0, 5)
    uIPadding.Parent = slider

    local slot = Instance.new("Frame")
    slot.Name = "slot"
    slot.AnchorPoint = Vector2.new(0.5, 0.5)
    slot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    slot.BorderSizePixel = 0
    slot.Position = UDim2.fromScale(0.5, 0.5)
    slot.Size = UDim2.new(1, 0, 0, 5)
    slot.Parent = slider

    local knobFrame = Instance.new("Frame")
    knobFrame.Name = "knob"
    knobFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    knobFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobFrame.BackgroundTransparency = 1
    knobFrame.Position = UDim2.fromScale(0, 0.5)
    knobFrame.Size = UDim2.fromOffset(60, 60)
    knobFrame.ZIndex = 5 --keyboard button support
    knobFrame.Parent = slider
    --#endregion

    -- Knob Button
    local knobButton = KeyboardButton.new(true)
    knobButton:RoundOff()
    knobButton:SetColor(Color3.fromRGB(50, 195, 185))
    knobButton:Outline(4, Color3.fromRGB(255, 255, 255))
    knobButton:Mount(knobFrame, true)
    maid:GiveTask(knobButton)

    -- Sliding Logic
    local slidingMaid = Maid.new()
    maid:GiveTask(slidingMaid)
    local updateSignal = Signal.new()
    maid:GiveTask(updateSignal)

    local currentValue = MathUtil.round(startValue, SLIDER_DECIMALS)

    -- Sliding
    maid:GiveTask(knobButton.InternalPress:Connect(function()
        slidingMaid:GiveTask(RunService.RenderStepped:Connect(function()
            -- Calculate where on the slider we have the knob
            local mousePosition = InputController.getMouseLocation(false)

            local ourValue = mousePosition.X - slot.AbsolutePosition.X
            local maxValue = slot.AbsoluteSize.X

            local value = MathUtil.round(MathUtil.map(ourValue, 0, maxValue, 0, 1, true), SLIDER_DECIMALS)
            if value ~= currentValue then
                currentValue = value
                knobFrame.Position = UDim2.fromScale(currentValue, 0.5)
                updateSignal:Fire(currentValue)
            end
        end))
    end))
    maid:GiveTask(knobButton.InternalRelease:Connect(function()
        slidingMaid:Cleanup()
    end))

    return updateSignal,
        function(forceValue: number)
            currentValue = forceValue
            knobFrame.Position = UDim2.fromScale(currentValue, 0.5)
        end
end

function VolumeWindow.new()
    local volumeWindow = TitledWindow.new(Images.ButtonIcons.Settings, "Settings", "Customise your experience")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local settingsWindow = Instance.new("Frame")
    settingsWindow.Name = "settingsWindow"
    settingsWindow.BackgroundTransparency = 1
    settingsWindow.Size = UDim2.fromScale(1, 1)

    local uIListLayout = Instance.new("UIListLayout")
    uIListLayout.Name = "uIListLayout"
    uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uIListLayout.Parent = settingsWindow

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 20)
    uIPadding.PaddingLeft = UDim.new(0, 20)
    uIPadding.PaddingRight = UDim.new(0, 20)
    uIPadding.PaddingTop = UDim.new(0, 20)
    uIPadding.Parent = settingsWindow
    --#endregion

    -- Music Volume
    do
        -- Create UI
        local musicVolumeFrame = createSettingLine(volumeWindow:GetMaid(), "Music Volume")
        musicVolumeFrame.Parent = settingsWindow

        -- Slider
        local musicVolumeSliderSignal, forceValue = createInteractionSlider(volumeWindow:GetMaid(), musicVolumeFrame.interaction, 0.5)
        forceValue(SettingsController.getSettingValue("Volume", "Music"))

        -- Update setting when we slide
        musicVolumeSliderSignal:Connect(function(volume: any)
            SettingsController.updateSettingValue("Volume", "Music", volume)
        end)
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    settingsWindow.Parent = volumeWindow:GetWindowHolder()

    return volumeWindow
end

return VolumeWindow
