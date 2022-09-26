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
local VehicleController: typeof(require(Paths.Client.VehicleController))

local DEBOUNCE_SCOPE = "VehiclesScreen"
local DEBOUNCE_MOUNT = {
    Key = "MountVehicle",
    Timeframe = 0.5,
}

local templates = Paths.Templates.Vehicles
local screenGui: ScreenGui = Paths.UI.Vehicles
local menu: Frame = screenGui.Menu
local menuList: ScrollingFrame = menu.List
local dashboard: Frame = screenGui.Dashboard
local dismountButton: ImageButton = dashboard.Dismount
local closeButton: ImageButton = menu.Header.Close
local uiStateMachine = UIController.getStateMachine()

function VehiclesUI.Init()
    VehicleController = require(Paths.Client.VehicleController)
end

function VehiclesUI.openDashboard()
    dashboard.Visible = true
    VehicleController.DrivingSession:GiveTask(function()
        dashboard.Visible = false
    end)
end

function VehiclesUI.openMenu()
    ScreenUtil.inUp(menu)
end

function VehiclesUI.exitMenu()
    ScreenUtil.out(menu)
end

-- Register UIState
do
    local function enter()
        VehiclesUI.openMenu()
    end

    local function exit()
        VehiclesUI.exitMenu()
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

-- Setup UI
do
    -- Create Vehicle Buttons
    for vehicleName, _vehicleProperties in pairs(VehicleConstants) do
        local item = templates.ListItem:Clone()
        item.Name = vehicleName
        item:FindFirstChild("Name").Text = vehicleName
        item.Parent = menuList

        item.MouseButton1Down:Connect(function()
            VehiclesUI.exitMenu()

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

-- Dismounting
do
    dismountButton.MouseButton1Down:Connect(function()
        VehicleController.DrivingSession:Cleanup()
    end)
end

return VehiclesUI
