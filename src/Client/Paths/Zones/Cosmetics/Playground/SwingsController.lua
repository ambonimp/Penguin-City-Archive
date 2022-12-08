local SwingsController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

local MAX_SPEED = 5

local function tickVehicleSeat(humanoid: Humanoid, hingeConstraint: HingeConstraint)
    -- Get throttle
    local moveDirection = humanoid.MoveDirection
    local throttle = -moveDirection.X

    -- Update throttle / acuator type
    if throttle == 0 then
        hingeConstraint.ActuatorType = Enum.ActuatorType.None
        return
    else
        hingeConstraint.ActuatorType = Enum.ActuatorType.Motor
    end

    hingeConstraint.AngularVelocity = throttle * MAX_SPEED
end

local function setupSwingObject(swingObject: Model, maid: typeof(Maid.new()))
    -- RETURN: Couldn't get everything :c
    local seat = swingObject:FindFirstChildWhichIsA("Seat", true)
    local hingeConstraint = swingObject:FindFirstChildWhichIsA("HingeConstraint", true)
    if not (seat and hingeConstraint) then
        return
    end

    local sitMaid = Maid.new()
    maid:GiveTask(sitMaid)

    maid:GiveTask(seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        sitMaid:Cleanup()

        local humanoid = seat.Occupant
        local localCharacter = Players.LocalPlayer.Character
        local isLocalPlayer = humanoid and localCharacter and humanoid:IsDescendantOf(localCharacter)
        if isLocalPlayer then
            sitMaid:GiveTask(RunService.Heartbeat:Connect(function()
                tickVehicleSeat(humanoid, hingeConstraint)
            end))
        end
    end))
end

function SwingsController.onZoneUpdate(maid: typeof(Maid.new()), zoneModel: Model)
    local swingObjects = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.Swing)
    for _, swingObject in pairs(swingObjects) do
        if swingObject:IsDescendantOf(zoneModel) then
            setupSwingObject(swingObject, maid)
        end
    end
end

return SwingsController
