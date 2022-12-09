local Swings = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local AttachmentUtil = require(Paths.Shared.Utils.AttachmentUtil)

local LOOK_VECTOR_EPSILON = 0.1

local function setupSwingObject(swingObject: Model)
    -- Read Structure
    local top: BasePart = swingObject.Top
    local model: Model = swingObject.Model
    local seat = model:FindFirstChildWhichIsA("Seat", true)

    -- Attachments
    local topAttachment = Instance.new("Attachment")
    topAttachment.Parent = top
    topAttachment.WorldAxis = Vector3.new(-math.abs(topAttachment.WorldAxis.X), 0, -math.abs(topAttachment.WorldAxis.Z)) -- This helps ensure forward throttle is forward!
    task.wait() -- Give time for topAttachment changes to propogate, so pivoting is accurate

    local seatAttachment = Instance.new("Attachment")
    seatAttachment.Parent = seat
    AttachmentUtil.pivot(seatAttachment, topAttachment)

    -- Hinge
    local hingeConstraint = Instance.new("HingeConstraint")
    hingeConstraint.ActuatorType = Enum.ActuatorType.Motor
    hingeConstraint.Attachment0 = topAttachment
    hingeConstraint.Attachment1 = seatAttachment
    hingeConstraint.MotorMaxTorque = math.huge
    hingeConstraint.LowerAngle = 0
    hingeConstraint.UpperAngle = 0
    hingeConstraint.Parent = seat

    -- Setup Model
    ModelUtil.weld(model)
    ModelUtil.unanchor(model)
    ModelUtil.canCollide(model, false)
    model.PrimaryPart = seat
    top.Transparency = 1
    seat.Transparency = 1

    -- Occupant network ownership
    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        -- Get occupying player
        local humanoid = seat.Occupant
        local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil

        -- Network Ownership
        for _, modelDescendant: BasePart in pairs(model:GetDescendants()) do
            if modelDescendant:IsA("BasePart") then
                modelDescendant:SetNetworkOwner(player)
            end
        end

        -- Hinge Management
        local isEmpty = not player
        hingeConstraint.LimitsEnabled = isEmpty -- Will reset it back to default angle
    end)
end

local function verifySwingObject(swingObject: Instance)
    if not swingObject:IsA("Model") then
        error("Not a model")
    end

    local top: BasePart = swingObject:FindFirstChild("Top")
    if not top then
        error("No `Top` part found - place this at the top of the swing")
    end

    local model: Model = swingObject.Model
    if not model then
        error("No `Model` found - place all the parts that visually make up the swing (seat, ropes etc..)")
    end

    local seat = model:FindFirstChildWhichIsA("Seat", true)
    if not seat then
        error("No `Seat` found")
    end

    -- ERROR: Top and Seat must be facing a very similair direction!
    local topLookVector = top.CFrame.LookVector
    local seatLookVector = seat.CFrame.LookVector
    if (topLookVector - seatLookVector).Magnitude > LOOK_VECTOR_EPSILON then
        error("`Top` and `Seat` are facing different directions")
    end

    -- ERROR: Must be all anchored!
    for _, descendant in pairs(swingObject:GetDescendants()) do
        if descendant:IsA("BasePart") and not descendant.Anchored then
            error(("%s is not Anchored!"):format(descendant:GetFullName()))
        end
    end
end

function Swings.zoneSetup()
    local swingObjects = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.Swing)
    for _, swingObject in pairs(swingObjects) do
        local success, errorMessage = pcall(verifySwingObject, swingObject)
        if not success then
            warn(("Issue with tagged SwingObject %s: %q"):format(swingObject:GetFullName(), errorMessage))
        else
            task.spawn(setupSwingObject, swingObject)
        end
    end
end

return Swings
