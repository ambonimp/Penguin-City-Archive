local SledRaceSled = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local sledTemplate = ServerStorage.Minigames.SledRace.Sled

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SledRaceSled.spawnSled(player: Player, spawnPoint: BasePart)
    SledRaceSled.removeSled(player)

    local character: Model = player.Character
    local model: Model = sledTemplate:Clone()
    model.Name = SledRaceConstants.SledName
    model:PivotTo(spawnPoint.CFrame * CFrame.new(0, (-spawnPoint.Size + model:GetExtentsSize()).Y / 2, 0))
    model.Parent = character

    local seat: Seat = model.Seat
    local seatWeld: Weld = BasePartUtil.weld(seat, character.HumanoidRootPart, seat, "Weld")
    seatWeld.Name = "SeatWeld"
    seatWeld.C0 = CFrame.new((seat.Size / 2 + character.Body.Main_Bone.Position) * Vector3.new(0, -1, 0))
end

function SledRaceSled.removeSled(player)
    local sled = SledRaceUtil.getSled(player)
    if sled then
        sled:Destroy()
    end
end

-------------------------------------------------------------------------------
-- TEMPLATE
-------------------------------------------------------------------------------
do
    -- Initialize runner template
    local cframe: CFrame, size: Vector3 = sledTemplate:GetBoundingBox()

    local physicsPart = Instance.new("Part")
    physicsPart.Name = "Physics"
    physicsPart.CFrame = cframe
    physicsPart.Size = size
    physicsPart.CanCollide = true
    physicsPart.Anchored = true
    physicsPart.Color = Color3.fromRGB(255, 0, 0)
    physicsPart.Transparency = 0
    PhysicsService:SetPartCollisionGroup(physicsPart, CollisionsConstants.Groups.SledRaceSleds)
    physicsPart.CustomPhysicalProperties = SledRaceConstants.SledPhysicalProperties

    local attachment = Instance.new("Attachment")
    attachment.Parent = physicsPart

    local move = Instance.new("VectorForce")
    move.Name = "Move"
    move.Force = Vector3.new()
    move.RelativeTo = Enum.ActuatorRelativeTo.World
    move.Attachment0 = attachment
    move.ApplyAtCenterOfMass = true
    move.Parent = physicsPart

    local steer = Instance.new("Torque")
    steer.Name = "Steer"
    steer.Attachment0 = attachment
    steer.RelativeTo = Enum.ActuatorRelativeTo.World
    steer.Parent = physicsPart

    local alignRotation = Instance.new("AngularVelocity")
    alignRotation.Name = "AlignRotation"
    alignRotation.Attachment0 = attachment
    alignRotation.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    alignRotation.Parent = physicsPart

    for _, displayPart in pairs(sledTemplate:GetChildren()) do
        displayPart.Massless = true
        displayPart.CanCollide = false
        displayPart.CanTouch = false
        displayPart.CanQuery = false
        BasePartUtil.weld(displayPart, physicsPart)
    end

    physicsPart.Parent = sledTemplate
    sledTemplate.PrimaryPart = physicsPart
end

return SledRaceSled
