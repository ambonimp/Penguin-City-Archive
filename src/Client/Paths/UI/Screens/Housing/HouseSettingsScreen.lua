local HouseSettingsScreen = {}

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)

local screenGui: ScreenGui = Paths.UI.Housing
local frame: Frame = screenGui.Settings

local uiStateMachine = UIController.getStateMachine()

local plotAt: Model

-- Register UIState
do
    local function open(data)
        plotAt = data.PlotAt
        InteractionUtil.hideInteractions(script.Name)

        ScreenUtil.sizeIn(frame)
    end

    local function close()
        InteractionUtil.showInteractions(script.Name)
        ScreenUtil.sizeOut(frame)
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.PlotSettings, open, close)
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        uiStateMachine:Pop()
    end)
    exitButton:Mount(frame.ExitButton, true)

    -- Way better, don't have to worry about things loading
    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        -- RETURN: Player isn't interacting with a mailbox
        if prompt.ObjectText ~= "Mailbox" then
            return
        end

        -- RETURN: UI derived from this prompts are already opened
        local state = uiStateMachine:GetState()
        if
            state == UIConstants.States.PlotSettings
            or state == UIConstants.States.HouseSelectionUI
            or state == UIConstants.States.PlotChanger
        then
            return
        end

        -- TODO: Switch this to a radial menu
        uiStateMachine:Push(UIConstants.States.PlotSettings, {
            PlotAt = prompt.Parent.Parent,
        })
    end)
end

do
    local plotChangeButton = WideButton.blue("Change Plot")
    plotChangeButton.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.PlotChanger, { PlotAt = plotAt })
    end)
    plotChangeButton:Mount(frame.Center.PlotChange, true)

    local houseChangeButton = WideButton.blue("Change House")
    houseChangeButton.Pressed:Connect(function() end)
    houseChangeButton:Mount(frame.Center.HouseChange, true)
end

return HouseSettingsScreen
