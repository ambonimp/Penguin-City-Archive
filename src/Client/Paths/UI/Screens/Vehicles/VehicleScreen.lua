local VehiclesUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local VehicleConstants = require(Paths.Shared.Constants.VehicleConstants)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Limiter = require(Paths.Shared.Limiter)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

local DEBOUNCE_SCOPE = "VehiclesScreen"
local DEBOUNCE_MOUNT = {
    Key = "MountVehicle",
    Timeframe = 0.5,
}

local player = Players.LocalPlayer

local templates = Paths.Templates.Vehicles
local screenGui: ScreenGui = Paths.UI.Vehicles
local menu: Frame = screenGui.Menu
local menuList: ScrollingFrame = menu.List
local dashboard: Frame = screenGui.Dashboard
local dismountButton: ImageButton = dashboard.Dismount
local closeButton: ImageButton = menu.Header.Close
local uiStateMachine = UIController.getStateMachine()

-- Setup UI
do
    -- Create Vehicle Buttons
    for vehicleName, _vehicleProperties in pairs(VehicleConstants) do
        local item = templates.ListItem:Clone()
        item.Name = vehicleName
        item:FindFirstChild("Name").Text = vehicleName
        item.Parent = menuList

        item.MouseButton1Down:Connect(function()
            uiStateMachine:Pop()

            -- RETURN: Not free
            local isFree = Limiter.debounce(DEBOUNCE_SCOPE, DEBOUNCE_MOUNT.Key, DEBOUNCE_MOUNT.Timeframe)
            if not isFree then
                return
            end

            Remotes.fireServer("MountVehicle", vehicleName)
        end)
    end

    -- Show
    screenGui.Enabled = true
    menu.Visible = false
    dashboard.Visible = false
end

-- Dashboard mounting / dismounting
do
    local dismountConn

    local function dismount()
        dismountConn:Disconnect()
        dashboard.Visible = false
    end

    Remotes.bindEvents({
        VehicleMounted = function()
            dashboard.Visible = true
            dismountConn = player.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(dismount)
        end,
    })

    dismountButton.MouseButton1Down:Connect(function()
        Remotes.fireServer("UnmountFromVehicle")
        dismount()
    end)
end

-- Register UIState
do
    local function enter()
        ScreenUtil.inUp(menu)
    end

    local function exit()
        ScreenUtil.out(menu)
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.Vehicles, enter, exit)
end

-- Manipulate UIState
do
    closeButton.MouseButton1Down:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.Vehicles)
    end)

    -- TODO: Replace this with something on the HUD
    UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: Game processed event
        if gameProcessedEvent then
            return
        end

        if inputObject.KeyCode == Enum.KeyCode.E then
            local isOpen = uiStateMachine:GetState() == UIConstants.States.Vehicles
            if isOpen then
                uiStateMachine:Pop()
            else
                uiStateMachine:Push(UIConstants.States.Vehicles)
            end
        end
    end)
end

return VehiclesUI
