local SportsGamesUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SportsGamesConstants = require(ReplicatedStorage.Shared.SportsGames.SportsGamesConstants)
local VectorUtil = require(ReplicatedStorage.Shared.Utils.VectorUtil)
local Vector3Util = require(ReplicatedStorage.Shared.Utils.Vector3Util)

function SportsGamesUtil.pushEquipment(player: Player, sportsEquipmentType: string, sportsEquipment: BasePart | Model)
    -- RETURN: No character
    local character = player.Character
    if not character then
        return
    end

    -- Get direct Direction Vector
    local characterToEquipment: Vector3 =
        VectorUtil.getUnit(Vector3Util.getXZComponents(sportsEquipment:GetPivot().Position - character:GetPivot().Position))

    -- Apply Force
    local primaryPart = sportsEquipment:IsA("BasePart") and sportsEquipment or sportsEquipment.PrimaryPart
    local pushEquipmentForce = SportsGamesConstants.PushEquipmentForceByType[sportsEquipmentType]
    if primaryPart then
        primaryPart.AssemblyLinearVelocity = Vector3.new(
            characterToEquipment.X * pushEquipmentForce.Horizontal,
            pushEquipmentForce.Vertical,
            characterToEquipment.Z * pushEquipmentForce.Horizontal
        )
    end
end

function SportsGamesUtil.getSportsEquipment(sportsEquipmentType: string): BasePart | Model
    if sportsEquipmentType == SportsGamesConstants.SportsEquipmentType.Football then
        return game.ReplicatedStorage.Assets.Misc.Football
    end

    if sportsEquipmentType == SportsGamesConstants.SportsEquipmentType.HockeyPuck then
        return game.ReplicatedStorage.Assets.Misc.HockeyPuck
    end

    error(("Undefined equipment for type %q"):format(sportsEquipmentType))
end

function SportsGamesUtil.getPushSoundName(sportsEquipmentType: string)
    if sportsEquipmentType == SportsGamesConstants.SportsEquipmentType.Football then
        return "FootballPunt"
    end

    if sportsEquipmentType == SportsGamesConstants.SportsEquipmentType.HockeyPuck then
        return "HockeyPuckHit"
    end

    error(("Undefined sound for type %q"):format(sportsEquipmentType))
end

return SportsGamesUtil
