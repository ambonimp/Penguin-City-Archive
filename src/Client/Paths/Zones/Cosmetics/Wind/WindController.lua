local WindController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local WindEmitter = require(Paths.Client.Zones.Cosmetics.Wind.WindEmitter)
local Maid = require(Paths.Packages.maid)
local AttachmentUtil = require(Paths.Shared.Utils.AttachmentUtil)
local CFrameUtil = require(Paths.Shared.Utils.CFrameUtil)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneController = require(Paths.Client.Zones.ZoneController)

local windMaid = Maid.new()

-------------------------------------------------------------------------------
-- Wind Emitter
-------------------------------------------------------------------------------

function WindController.startWind()
    windMaid:Cleanup()

    -- Wind Emitter
    local windEmitter = WindEmitter.new()
    windEmitter:Start()
    windMaid:GiveTask(windEmitter)
end

function WindController.stopWind()
    windMaid:Cleanup()
end

-------------------------------------------------------------------------------
-- Zones
-------------------------------------------------------------------------------

local function createAnimatedFlag(markerFlag: BasePart, maid: typeof(Maid.new()))
    -- Overlay an AnimatedFlag Model over our markerFlag
    local markerAttachment: Attachment = markerFlag:FindFirstChildOfClass("Attachment")

    local animatedFlag: Model = ReplicatedStorage.Assets.Misc.AnimatedFlag:Clone()
    local flagPart: MeshPart = animatedFlag.FlagPart
    local flagAttachment: Attachment = flagPart.Attachment
    local animator: Animator = animatedFlag.AnimationController.Animator
    local idleAnimation: Animation = animator.Idle

    animatedFlag.Parent = markerFlag.Parent
    task.wait() -- Ensure time to enter the workspace properly, so attachment cframes are proper

    -- Resize
    local scale = math.max(markerFlag.Size.X, markerFlag.Size.Y, markerFlag.Size.Z)
        / math.max(flagPart.Size.X, flagPart.Size.Y, flagPart.Size.Z)
    ModelUtil.scale(animatedFlag, scale)

    -- Position
    local markerAttachmentPosition = AttachmentUtil.getWorldCFrame(markerAttachment).Position
    local flagAttachmentPosition = AttachmentUtil.getWorldCFrame(flagAttachment).Position

    local newPosition = animatedFlag:GetPivot().Position + (markerAttachmentPosition - flagAttachmentPosition)
    animatedFlag:PivotTo(CFrameUtil.setPosition(animatedFlag:GetPivot(), newPosition))

    -- Disguise as markerFlag
    flagPart.Color = markerFlag.Color
    markerFlag.Transparency = 1

    maid:GiveTask(animatedFlag)

    -- Play Animation
    local idleTrack = animator:LoadAnimation(idleAnimation)
    idleTrack:Play()
    maid:GiveTask(idleTrack)
end

function ZoneController.onZoneUpdate(maid: typeof(Maid.new()), _zoneModel: Model)
    -- Flags
    local animatedFlags: { BasePart } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.AnimatedFlag)
    for _, animatedFlag in pairs(animatedFlags) do
        task.spawn(createAnimatedFlag, animatedFlag, maid)
    end
end

return WindController
