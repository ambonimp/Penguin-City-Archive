local SportsGamesUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SportsGamesConstants = require(ReplicatedStorage.Shared.SportsGames.SportsGamesConstants)
local VectorUtil = require(ReplicatedStorage.Shared.Utils.VectorUtil)
local Vector3Util = require(ReplicatedStorage.Shared.Utils.Vector3Util)

function SportsGamesUtil.pushEquipment(player: Player, sportsEquipment: BasePart | Model)
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
    if primaryPart then
        primaryPart.AssemblyLinearVelocity = Vector3.new(
            characterToEquipment.X * SportsGamesConstants.PushEquipmentForce.Horizontal,
            SportsGamesConstants.PushEquipmentForce.Vertical,
            characterToEquipment.Z * SportsGamesConstants.PushEquipmentForce.Horizontal
        )
    end
end

return SportsGamesUtil
