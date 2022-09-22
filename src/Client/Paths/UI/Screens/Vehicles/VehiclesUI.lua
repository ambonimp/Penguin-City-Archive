local VehiclesUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Modules = Paths.Modules
local Remotes = require(Modules.Remotes)
local VehicleConstants = require(Modules.Constants.VehicleConstants)
local UIController = require(Modules.UI.UIController)
local UIConstants = require(Modules.UI.UIConstants)
local Limiter = require(Modules.Limiter)
local Vehicles: typeof(require(Modules.Vehicles))

local DEBOUNCE_SCOPE = "VehiclesUI"
local DEBOUNCE_MOUNT = {
    Key = "MountVehicle",
    Timeframe = 0.5,
}

local ui = Paths.UI
local templates = Paths.Templates.Vehicles
local screenGui: ScreenGui = ui.Vehicles
local menu: Frame = screenGui.Menu
local menuList: ScrollingFrame = menu.List
local dashboard: Frame = screenGui.Dashboard
local dismountButton: ImageButton = dashboard.Dismount
local closeButton: ImageButton = menu.Header.Close
local uiStateMachine = UIController.getStateMachine()

function VehiclesUI.Init()
    Vehicles = require(Modules.Vehicles)
end

function VehiclesUI.openMenu()
    -- TODO: Screengui opener
    menu.Visible = true
end

function VehiclesUI.closeMenu()
    menu.Visible = false
end

function VehiclesUI.openDashboard()
    dashboard.Visible = true
    Vehicles.DrivingSession:GiveTask(function()
        dashboard.Visible = false
    end)
end

-- Register UIState
do
    local function enter()
        VehiclesUI.openMenu()
    end

    local function exit()
        VehiclesUI.closeMenu()
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
        Vehicles.DrivingSession:Cleanup()
    end)
end

return VehiclesUI
