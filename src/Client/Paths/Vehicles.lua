local Vehicles = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local Maid = require(Paths.Packages.maid)
local VehicleUI = require(Paths.Client.UI.Screens.Vehicles.VehiclesUI)
local VehicleUtil = require(Paths.Shared.Utils.VehicleUtil)

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local char
local togglePPConn -- Proxmity prompts

local function normalizeAngle(x)
    return x % (2 * math.pi)
end

local function minRot(x)
    x = normalizeAngle(x)
    local x2 = x - (2 * math.pi)
    return if math.abs(x) < math.abs(x2) then x else x2
end

local function drive(model)
    if char then
        VehicleUI.openDashboard()

        VehicleUtil.new(player, model)

        local _, y, _ = char.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
        local yaw = y

        Vehicles.DrivingSession:GiveTask(RunService.Heartbeat:Connect(function(dt)
            local move = controls:GetMoveVector()
            VehicleUtil.updateMove(move)

            -- Turning
            local deltaYaw = 0
            if VehicleUtil.getThrottle() ~= 0 then
                _, y, _ = camera.CFrame:ToEulerAnglesYXZ()
                local goalDir = y + math.atan2(-move.Z, move.X) - math.pi / 2

                deltaYaw = minRot(goalDir - yaw)
                yaw = yaw + deltaYaw * dt * 1.8
            end

            VehicleUtil.updateLook(dt, yaw, deltaYaw)

            VehicleUtil.applyFloatForce(dt)
            VehicleUtil.applyMoveFoce(dt)
        end))

        Vehicles.DrivingSession:GiveTask(function()
            VehicleUtil.destroy()

            -- If unmount button is clicked, make player jump of seat
            if char.Humanoid.SeatPart then
                Remotes.fireServer("UnmountFromVehicle")
            end
        end)
    end
end

Vehicles.DrivingSession = Maid.new()

function Vehicles.loadCharacter(character)
    char = character
    local hum = char.Humanoid

    -- Hide proxmity prompts when a vehicle is entered
    togglePPConn = hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local seatPart = hum.SeatPart
        if seatPart then
            if CollectionService:HasTag(hum.SeatPart.Parent.Parent, "Vehicle") then
                InteractionUtil.toggleVisible(script.Name, seatPart == nil)
            end
        else
            InteractionUtil.toggleVisible(script.Name, true)
        end
    end)
end

function Vehicles.unloadCharacter()
    char = nil

    togglePPConn:Disconnect()
    ProximityPromptService.Enabled = false

    InteractionUtil.toggleVisible(script.Name, true)
end

Remotes.bindEvents({
    MountVehicle = function(owner, vehicle)
        local driverSeat = vehicle.Seats.Driver

        if owner == player then
            InteractionUtil.createInteraction(driverSeat, {
                ActionText = "Drive",
                ObjectText = "DriverSeat",
            })

            if driverSeat.Occupant then
                drive(vehicle)
            end

            driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
                if driverSeat.Occupant then
                    drive(vehicle)
                else
                    Vehicles.DrivingSession:Cleanup()
                end
            end)
        else
            driverSeat:FindFirstChildOfClass("ProximityPrompt"):Destroy()
        end
    end,
})

return Vehicles
