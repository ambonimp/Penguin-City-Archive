local ResultsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Packages.maid)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local StampButton = require(Paths.Client.UI.Elements.StampButton)
local UIActions = require(Paths.Client.UI.UIActions)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

local NEXT_BUTTON_TEXT = "Next"

local screenGui: ScreenGui = Ui.Minigames.ResultsScreen
local resultsFrame: Frame = screenGui.Results
local logoLabel: ImageLabel = resultsFrame.Background.Logo
local valuesFrame: Frame = resultsFrame.Background.Values
local templateValueFrame: Frame = valuesFrame.template
local stampsHolder: Frame = resultsFrame.Background.Stamps.Stamps
local templateStampsFrame: Frame = stampsHolder.template
local nextButton = KeyboardButton.new()
local cachedNextCallback: (() -> nil) | nil
local openMaid = Maid.new()

function ResultsScreen.Init()
    local function close()
        UIController.getStateMachine():Remove(UIConstants.States.Results)

        if cachedNextCallback then
            cachedNextCallback()
        end
        cachedNextCallback = nil
    end

    -- Setup Buttons
    do
        nextButton:SetColor(UIConstants.Colors.Buttons.NextGreen, true)
        nextButton:SetText(NEXT_BUTTON_TEXT)
        nextButton:Mount(resultsFrame.NextButton, true)
        nextButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)

        nextButton.Pressed:Connect(close)
    end

    -- Closing
    UIController.registerStateCloseCallback(UIConstants.States.Results, close)

    -- Register UIState
    do
        local function enter(data: table)
            -- Read data
            local logoId = data.LogoId
            local values = data.Values
            local nextCallback = data.NextCallback
            local stampData = data.StampData

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
            if stampData then
                if typeof(stampData) == "table" then
                    for stampId, progress in pairs(stampData) do
                        if tostring(stampId) and tonumber(progress) then
                            local stamp = StampUtil.getStampFromId(stampId)
                            if not stamp then
                                error(("Bad data.StampData; no stamp %q"):format(stampId))
                            end
                        else
                            error(("Bad data.StampData (unexpected key/value pair) %q %q"):format(tostring(stampId), tostring(progress)))
                        end
                    end
                else
                    error("Bad data.StampData")
                end
            end

            ResultsScreen.open(logoId, values, nextCallback, stampData)
        end

        UIController.registerStateScreenCallbacks(UIConstants.States.Results, {
            Boot = enter,
            Shutdown = ResultsScreen.shutdown,
            Maximize = ResultsScreen.maximize,
            Minimize = ResultsScreen.minimize,
        })
    end

    -- Misc
    templateValueFrame.Visible = false
    templateStampsFrame.Visible = false
end

function ResultsScreen.open(
    logoId: string,
    values: { { Name: string, Value: any, Icon: string? } },
    nextCallback: (() -> nil)?,
    stampData: { [string]: number }?
)
    openMaid:Cleanup()
    cachedNextCallback = nextCallback

    logoLabel.Image = logoId

    -- Create new value frames
    for i, valueInfo in pairs(values) do
        -- ERROR: Bad valueInfo
        if not (typeof(valueInfo.Name) == "string") then
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
        openMaid:GiveTask(valueFrame)

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
    end

    -- Stamps
    if stampData then
        for stampId, progress in pairs(stampData) do
            local holder = templateStampsFrame:Clone()
            holder.Visible = true
            holder.Parent = stampsHolder
            openMaid:GiveTask(holder)

            local stamp = StampUtil.getStampFromId(stampId)
            local stampButton = StampButton.new(stamp, {
                Progress = progress,
            })
            stampButton.Pressed:Connect(function()
                UIActions.showStampInfo(stamp.Id, progress)
            end)
            stampButton:Mount(holder, true)

            openMaid:GiveTask(stampButton)
        end
    end
end

function ResultsScreen.maximize()
    ScreenUtil.inUp(resultsFrame)
    screenGui.Enabled = true
end

function ResultsScreen.minimize()
    ScreenUtil.outDown(resultsFrame)
end

return ResultsScreen
