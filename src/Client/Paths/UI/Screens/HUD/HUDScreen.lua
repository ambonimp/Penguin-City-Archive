local HUDScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)

local screenGui: ScreenGui = Ui.HUD

function HUDScreen.Init()
    -- Register UIState
    do
        local isInState = true

        local function enter()
            -- RETURN: Already entered
            if isInState then
                return
            end
            isInState = true

            HUDScreen.open()
        end

        local function exit()
            -- RETURN: Not in state
            if not isInState then
                return
            end
            isInState = false

            HUDScreen.close()
        end

        local function readState()
            if UIUtil.getPseudoState(UIConstants.States.HUD, UIController.getStateMachine()) then
                enter()
            else
                exit()
            end
        end

        UIController.getStateMachine():RegisterGlobalCallback(readState)
        readState()
    end
end

function HUDScreen.open()
    screenGui.Enabled = true
end

function HUDScreen.close()
    screenGui.Enabled = false
end

return HUDScreen
