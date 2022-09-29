local VehicleController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local Maid = require(Paths.Packages.maid)
local VehicleUtil = require(Paths.Shared.Utils.VehicleUtil)

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

-- Returns an angle within (0, math.pi * 2)
local function normalizeAngle(theta: number): number
    return theta % (2 * math.pi)
end

-- Returns the fastest way to reach an angle. For example minimizeTheta(270) = -90 since 90 < 270
local function minimizeTheta(x: number): number
    x = normalizeAngle(x)
    local x2 = x - (2 * math.pi)
    return if math.abs(x) < math.abs(x2) then x else x2
end

local function drive(model)
    -- RETURN: Character doesn't exist
    local character = player.Character
    if not character then
        return
    end

    VehicleUtil.new(player, model)

    local _, y, _ = character.HumanoidRootPart.CFrame:ToEulerAnglesYXZ()
    local yaw = y

    VehicleController.DrivingSession:GiveTask(RunService.Heartbeat:Connect(function(dt)
        local move = controls:GetMoveVector()
        VehicleUtil.updateMove(move)

        -- Turning
        local deltaYaw = 0
        if VehicleUtil.getThrottle() ~= 0 then
            _, y, _ = camera.CFrame:ToEulerAnglesYXZ()
            local goalDir = y + math.atan2(-move.Z, move.X) - math.pi / 2

            deltaYaw = minimizeTheta(goalDir - yaw)
            yaw = yaw + deltaYaw * dt * 1.8
        end

        VehicleUtil.updateDirection(dt, yaw, deltaYaw)

        VehicleUtil.applyFloatForce(dt)
        VehicleUtil.applyMoveFoce(dt)
    end))

    VehicleController.DrivingSession:GiveTask(function()
        VehicleUtil.destroy()

        -- If unmount button is clicked, make player jump of seat
        if character.Humanoid.SeatPart then
            Remotes.fireServer("UnmountFromVehicle")
        end
    end)
end

VehicleController.DrivingSession = Maid.new()

Remotes.bindEvents({
    VehicleMounted = function(owner, vehicle)
        InteractionUtil.hideInteractions(script.Name)

        local driving = owner == player
        if driving then
            drive(vehicle)
        end

        local dismountConn
        dismountConn = player.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
            dismountConn:Disconnect()
            InteractionUtil.showInteractions(script.Name)

            VehicleController.DrivingSession:Cleanup()
        end)
    end,
    VehicleCreated = function(owner, vehicle)
        local driverSeat = vehicle.Seats.Driver

        if owner == player then
            driverSeat:FindFirstChildOfClass("ProximityPrompt").ActionText = "Drive"

            if driverSeat.Occupant then
                drive(vehicle)
            end

            driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
                if driverSeat.Occupant then
                    drive(vehicle)
                else
                    VehicleController.DrivingSession:Cleanup()
                end
            end)
        else
            driverSeat:FindFirstChildOfClass("ProximityPrompt"):Destroy()
        end
    end,
})

return VehicleController
