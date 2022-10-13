local ResultsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

local NEXT_BUTTON_TEXT = "Next"

local screenGui: ScreenGui = Ui.Minigames.ResultsScreen
local resultsFrame: Frame = screenGui.Results
local logoLabel: ImageLabel = resultsFrame.Background.Logo
local valuesFrame: Frame = resultsFrame.Background.Values
local templateValueFrame: Frame = valuesFrame.template
local _stampsFrame: Frame = resultsFrame.Background.Stamps
local nextButton = KeyboardButton.new()
local cachedNextCallback: (() -> nil) | nil
local cachedValueFrames: { Frame } = {}

function ResultsScreen.Init()
    -- Setup Buttons
    do
        nextButton:SetColor(UIConstants.Colors.Buttons.NextGreen, true)
        nextButton:SetText(NEXT_BUTTON_TEXT)
        nextButton:Mount(resultsFrame.NextButton, true)
        nextButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)

        nextButton.Pressed:Connect(function()
            UIController.getStateMachine():Remove(UIConstants.States.Results)

            if cachedNextCallback then
                cachedNextCallback()
            end
            cachedNextCallback = nil
        end)
    end

    -- Register UIState
    do
        local function enter(data: table)
            -- Read data
            local logoId = data.LogoId
            local values = data.Values
            local stamps = data.Stamps
            local nextCallback = data.NextCallback

            -- Verify
            if not (logoId and tostring(logoId)) then
                error("Bad data.LogoId")
            end
            if not (values and typeof(values) == "table") then
                error("Bad data.Values")
            end
            if nextCallback and not typeof(nextCallback) == "function" then
                error("Bad data.NextCallback")
            end

            ResultsScreen.open(logoId, values, stamps, nextCallback)
        end

        local function exit()
            ResultsScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.Results, enter, exit)
    end

    -- Misc
    templateValueFrame.Visible = false
end

function ResultsScreen.open(
    logoId: string,
    values: { { Name: string, Value: any, Icon: string? } },
    _stamps: nil?,
    nextCallback: (() -> nil)?
)
    cachedNextCallback = nextCallback

    logoLabel.Image = logoId

    -- Clear old value frames
    for _, valueFrame in pairs(cachedValueFrames) do
        valueFrame:Destroy()
    end
    cachedValueFrames = {}

    -- Create new value frames
    for i, valueInfo in pairs(values) do
        -- ERROR: Bad valueInfo
        if not typeof(valueInfo.Name) == "string" then
            warn(values)
            error("valueInfo missing string .Name")
        end
        if valueInfo.Value == nil then
            warn(values)
            error("valueInfo missing any .Value")
        end
        if valueInfo.Icon and typeof(valueInfo.Icon) ~= "string" then
            warn(values)
            error("valueInfo has .Icon that is not a string")
        end

        local valueFrame = templateValueFrame:Clone()

        -- Name
        local name = valueInfo.Name
        valueFrame.Title.Text = name

        -- Value
        local value = valueInfo.Value
        local stringValue: string
        if typeof(value) == "number" then
            stringValue = StringUtil.commaValue(value)
        else
            stringValue = tostring(value)
        end
        valueFrame.Value.Text = stringValue

        -- Icon
        valueFrame.Title.Icon.Image = valueInfo.Icon or ""

        valueFrame.Visible = true
        valueFrame.Name = name
        valueFrame.LayoutOrder = -i -- Bottom up
        valueFrame.Parent = valuesFrame
        table.insert(cachedValueFrames, valueFrame)
    end

    screenGui.Enabled = true
end

function ResultsScreen.close()
    screenGui.Enabled = false
end

return ResultsScreen
