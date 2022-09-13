local UserInputService = game:GetService("UserInputService")

local Paths = require(script.Parent.Parent)
local ui = Paths.UI
local templates = Paths.Templates.Vehicles

local modules = Paths.Modules
local Remotes = modules.Remotes
local VehicleEnums = modules.VehicleEnums


local VehiclesUI = {}

local screenGui = ui.Vehicles
local menu = screenGui.Menu
local menuList = menu.List

local dashboard = screenGui.Dashboard
local dismountBtn = dashboard.Dismount

function VehiclesUI.openMenu()
    -- TODO: Screengui opener
    screenGui.Enabled = true
    menu.Visible = true

end

function VehiclesUI.openDashboard()
    dashboard.Visible = true
    modules.Vehicles.DrivingSession:GiveTask(function()
        dashboard.Visible = false
    end)
end


-- Load list
local spawnDb
for vehicle in VehicleEnums do
    local item = templates.ListItem:Clone()
    item.Name = vehicle
    item:FindFirstChild("Name").Text = vehicle
    item.Parent = menuList

    item.MouseButton1Down:Connect(function()
        if not spawnDb then
            spawnDb = true

            Remotes.fireServer("OnVehicleSpawned", vehicle)

            task.wait(0.2)
            spawnDb = false

        end

    end)

end

-- Menu
-- Opening / closing menu
menu.Header.Close.MouseButton1Down:Connect(function()
    screenGui.Enabled = false
end)

-- TODO: Replace this with something on the HUD
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        VehiclesUI.openMenu()
    end
end)


-- Dashboard
dismountBtn.MouseButton1Down:Connect(function()
    modules.Vehicles.DrivingSession:Destroy()
end)


return VehiclesUI