local SwingsController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)

local MAX_SPEED = 6
local MAX_ANGLE = 70

local function tickVehicleSeat(humanoid: Humanoid, hingeConstraint: HingeConstraint, angleDegrees: number)
    -- Get throttle
    local moveDirection = humanoid.MoveDirection
    local throttle = -math.sign(moveDirection.X) * math.ceil(math.abs(moveDirection.X))

    -- Update throttle / acuator type
    local doDisable = throttle == 0 or angleDegrees > MAX_ANGLE
    if doDisable then
        hingeConstraint.ActuatorType = Enum.ActuatorType.None
        hingeConstraint.AngularVelocity = 0
        return
    else
        hingeConstraint.ActuatorType = Enum.ActuatorType.Motor
    end

    local angleFactor = math.sqrt(1 - (angleDegrees / MAX_ANGLE))
    hingeConstraint.AngularVelocity = throttle * MAX_SPEED * angleFactor
end

local function setupSwingObject(swingObject: Model, maid: typeof(Maid.new()))
    -- RETURN: Couldn't get everything :c
    local top: BasePart = swingObject:FindFirstChild("Top")
    local seat = swingObject:FindFirstChildWhichIsA("Seat", true)
    local hingeConstraint = swingObject:FindFirstChildWhichIsA("HingeConstraint", true)
    if not (seat and hingeConstraint and top) then
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
                local currentAngleDegrees = VectorUtil.getAngle(top.CFrame.LookVector, seat.CFrame.LookVector)
                tickVehicleSeat(humanoid, hingeConstraint, currentAngleDegrees)
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
