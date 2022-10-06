local ZoneTransitionScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local Button = require(Paths.Client.UI.Elements.Button)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local Images = require(Paths.Shared.Images.Images)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)

local screenGui: ScreenGui = Ui.ZoneTransition

function ZoneTransitionScreen.Init()
    -- Register UIState
    do
        local function enter(data: table?)
            ZoneTransitionScreen.open(data)
        end

        local function exit()
            ZoneTransitionScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.ZoneTransition, enter, exit)
    end
end

-------------------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------------------

function ZoneTransitionScreen.open()
    screenGui.Enabled = true
end

function ZoneTransitionScreen.close()
    screenGui.Enabled = false
end

return ZoneTransitionScreen
