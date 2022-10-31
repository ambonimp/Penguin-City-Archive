local SledRaceSled = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
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
    local character: Model = player.Character

    -- Clean up
    SledRaceSled.removeSled(player)

    -- Set up character
    CharacterUtil.setEthereal(player, true, "SledRace")

    -- Set up sled
    local sled: Model = sledTemplate:Clone()
    sled.Name = SledRaceConstants.SledName

    local sledRoot: BasePart = sled.PrimaryPart
    sled:PivotTo(spawnPoint.CFrame * CFrame.new(0, (-spawnPoint.Size + sledRoot.Size).Y / 2, 0))
    sled.Parent = character

    local seat: Seat = sled.Seat
    seat:Sit(character.Humanoid)

    return character
end

function SledRaceSled.removeSled(player)
    SledRaceUtil.getSled(player):Destroy()
end

-------------------------------------------------------------------------------
-- TEMPLATE
-------------------------------------------------------------------------------
do
    -- Initialize runner template
    local cframe: CFrame, size: Vector3 = sledTemplate:GetBoundingBox()

    local physicsPart = Instance.new("Part")
    physicsPart.CFrame = cframe
    physicsPart.Size = size
    physicsPart.CanCollide = true
    physicsPart.Anchored = true
    physicsPart.Transparency = 1
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
        BasePartUtil.weldTo(displayPart, physicsPart, displayPart)
    end

    physicsPart.Parent = sledTemplate
    sledTemplate.PrimaryPart = physicsPart
end

return SledRaceSled
