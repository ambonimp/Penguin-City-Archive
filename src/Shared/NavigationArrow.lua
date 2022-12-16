--[[
    Arrow to point 1 thing to another; used in the tutorial!
]]
local NavigationArrow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage.Packages.maid)

--[[
    Returns an Attachment, and a boolean as true if we created it
]]
local function getAttachmentFromInstance(instance: Instance | Attachment | PVInstance)
    -- Attachment
    if instance:IsA("Attachment") then
        return instance, false
    end

    -- ERROR: No BasePart
    local basePart: BasePart = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart", true)
    if not basePart then
        error(("Could not add attachment to instance %s; no BasePart found!"):format(instance:GetFullName()))
    end

    -- PVInstance
    if instance:IsA("PVInstance") then
        local attachment = Instance.new("Attachment")
        attachment.Name = "NavigationArrowAttachment"
        attachment.Parent = basePart

        attachment.WorldCFrame = instance:GetPivot()

        return attachment, true
    end

    -- ERROR: Missing edgecase
    error(("Don't know how to create attachment for instance %s (%q)"):format(instance:GetFullName(), instance.ClassName))
end

local function createBeam(fromAttachment: Attachment, toAttachment: Attachment)
    local beam = Instance.new("Beam")
    beam.Name = "NavigationArrowBeam"
    beam.Attachment0 = toAttachment
    beam.Attachment1 = fromAttachment
    beam.FaceCamera = true
    beam.LightInfluence = 1
    beam.Segments = 1
    beam.Texture = "rbxassetid://11832262566"
    beam.TextureLength = 5
    beam.TextureMode = Enum.TextureMode.Static
    beam.TextureSpeed = -0.6
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    beam.Width0 = 4
    beam.Width1 = 4
    beam.Parent = game.Workspace

    return beam
end

function NavigationArrow.new()
    local navigationArrow = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function navigationArrow:GuidePlayer(player: Player, toInstance: Instance)
        -- WARN: No character
        local character = player.Character
        if not (character and character.PrimaryPart) then
            warn(("Could not guide %s; no character!"):format(player.Name))
            return
        end

        return navigationArrow:Mount(character.PrimaryPart, toInstance)
    end

    function navigationArrow:Mount(from: Instance, to: Instance)
        maid:Cleanup()

        -- Get Attachments
        local fromAttachment, didCreateFromAttachment = getAttachmentFromInstance(from)
        if didCreateFromAttachment then
            maid:GiveTask(fromAttachment)
        end

        local toAttachment, didCreateToAttachment = getAttachmentFromInstance(to)
        if didCreateToAttachment then
            maid:GiveTask(toAttachment)
        end

        -- Beam
        local beam = createBeam(fromAttachment, toAttachment)
        maid:GiveTask(beam)
    end

    -- Clears beam
    function navigationArrow:Clear()
        maid:Cleanup()
    end

    -- Cleans up the internal maid - this object can be reused after destruction
    function navigationArrow:Destroy()
        maid:Cleanup()
    end

    return navigationArrow
end

return NavigationArrow
