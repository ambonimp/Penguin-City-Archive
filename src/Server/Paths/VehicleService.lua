local VehicleService = {}

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local VehicleConstants = require(Paths.Shared.Constants.VehicleConstants)
local Interactionutil = require(Paths.Shared.Utils.InteractionUtil)
local VehicleUtil = require(Paths.Shared.Utils.VehicleUtil)

local spawnedVehicles = {}

local function attachment(platform)
    local att = Instance.new("Attachment")
    att.Parent = platform

    return att
end

local function vectorForce(platform, name)
    local actuator = Instance.new("VectorForce")
    actuator.Name = name
    actuator.Force = Vector3.new()
    actuator.Parent = platform
    actuator.ApplyAtCenterOfMass = true
    actuator.Attachment0 = platform:FindFirstChildOfClass("Attachment")
    actuator.RelativeTo = Enum.ActuatorRelativeTo.World

    return actuator
end

local function alignOrientation(platform, name)
    local actuator = Instance.new("AlignOrientation")
    actuator.Name = name
    actuator.Mode = Enum.OrientationAlignmentMode.OneAttachment
    actuator.Attachment0 = platform:FindFirstChildOfClass("Attachment")
    actuator.RigidityEnabled = true
    actuator.Parent = platform

    return actuator
end

local function setNetworkOwner(model, owner)
    for _, basePart in model:GetDescendants() do
        if basePart:IsA("BasePart") then
            basePart:SetNetworkOwner(owner)
        end
    end
end

function VehicleService.unmountFromVehicle(player: Player)
    -- RETURN: No seat part found
    local seat: (BasePart | Seat)? = player.Character.Humanoid.SeatPart
    if not seat then
        return
    end

    seat.Disabled = true
    task.wait()
    seat.Disabled = false
end

function VehicleService.mountVehicle(client: Player, vehicleName: string)
    local prevVehicle = spawnedVehicles[client]
    if prevVehicle then
        prevVehicle:Destroy()
        Remotes.fireClient(client, "VehicleDestroyed")
    end

    if VehicleConstants[vehicleName] then
        local model = ServerStorage.Vehicles[vehicleName]:Clone()
        model.Parent = workspace
        spawnedVehicles[client] = model
        CollectionService:AddTag(model, "Vehicle")

        local platform = model.Platform

        -- Actuators
        attachment(platform)
        alignOrientation(platform, "Look")
        vectorForce(platform, "Move")
        vectorForce(platform, "Float")

        local simulating, simulation, yaw
        simulation = RunService.Heartbeat:Connect(function(dt)
            local currentVehicle = spawnedVehicles[client]
            if currentVehicle == model then
                if simulating then
                    VehicleUtil.updateLook(dt, yaw, 0)

                    VehicleUtil.applyFloatForce(dt)
                    VehicleUtil.applyMoveFoce(dt)
                end
            else
                if not currentVehicle then
                    VehicleUtil.destroy()
                end

                simulation:Disconnect()
            end
        end)

        local interaction
        for _, seat in model.Seats:GetChildren() do
            if seat.Name == "Driver" then
                interaction = Interactionutil.createInteraction(seat, { ObjectText = "DriverSeat", ActionText = "Drive" })

                local char = client.Character
                local hum = char.Humanoid
                local hrp = char.HumanoidRootPart

                seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    local occupant = seat.Occupant

                    if occupant then
                        if occupant ~= hum then
                            occupant:Destroy()
                        else
                            setNetworkOwner(model, client)
                            simulating = false
                        end
                    else
                        setNetworkOwner(model)

                        VehicleUtil.new(client, model)
                        VehicleUtil.updateMove(Vector3.new())

                        _, yaw, _ = platform.CFrame:ToEulerAnglesYXZ()

                        simulating = true
                    end
                end)

                -- Vehicle spawns at character
                -- TODO: position can be specified
                model.WorldPivot = seat.CFrame
                model:PivotTo(hrp.CFrame)

                seat:Sit(hum)
                Remotes.fireAllClients("MountVehicle", client, model)
            else
                interaction = Interactionutil.createInteraction(seat, { ObjectText = "PassengerSeat", ActionText = "Enter" })
            end

            seat.CanCollide = false
            seat.CanTouch = false
            seat.CanQuery = false

            interaction.Triggered:Connect(function(player)
                if not seat.Occupant then
                    seat:Sit(player.Character.Humanoid)
                end
            end)
        end
    end
end

Remotes.bindEvents({
    UnmountFromVehicle = VehicleService.unmountFromVehicle,
    MountVehicle = VehicleService.mountVehicle,
})

return VehicleService