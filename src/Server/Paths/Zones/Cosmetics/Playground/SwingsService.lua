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

    local seatAttachment = Instance.new("Attachment")
    seatAttachment.Parent = seat
    AttachmentUtil.pivot(seatAttachment, topAttachment)

    -- Setup Model
    ModelUtil.weld(model)
    ModelUtil.unanchor(model)
    model.PrimaryPart = seat
    top.Transparency = 1

    -- Occupant network ownership
    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
        seat:SetNetworkOwner(player)
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
            setupSwingObject(swingObject)
        end
    end
end

return Swings
