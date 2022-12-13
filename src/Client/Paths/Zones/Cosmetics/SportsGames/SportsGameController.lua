local SportsGameController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local SportsGamesConstants = require(Paths.Shared.SportsGames.SportsGamesConstants)
local SportsGamesUtil = require(Paths.Shared.SportsGames.SportsGamesUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local Limiter = require(Paths.Shared.Limiter)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local NetworkOwnerUtil = require(Paths.Shared.Utils.NetworkOwnerUtil)

local function setupSportsEquipment(sportsEquipment: BasePart | Model, maid: typeof(Maid.new()))
    -- Network Ownership; whoever touches it then owns it
    maid:GiveTask(sportsEquipment.Touched:Connect(function(otherPart)
        -- RETURN: Not our local player
        local player = CharacterUtil.getPlayerFromCharacterPart(otherPart)
        if not (player and player == Players.LocalPlayer) then
            return
        end

        -- RETURN: Touched  very recently
        local isFree = Limiter.debounce("SportsGame", player, SportsGamesConstants.PlayerTouchDebounceTime)
        if not isFree then
            return
        end

        -- RETURN: We don't have network ownership
        local hasNetworkOwnership = false
        for _, instance: BasePart in pairs(ArrayUtil.merge(sportsEquipment:GetDescendants(), { sportsEquipment })) do
            if instance:IsA("BasePart") then
                hasNetworkOwnership = hasNetworkOwnership or NetworkOwnerUtil.getNetworkOwner(instance) == player
            end
        end
        if not hasNetworkOwnership then
            return
        end

        -- Apply Force locally!
        SportsGamesUtil.pushEquipment(player, sportsEquipment)
    end))
end

function SportsGameController.onZoneUpdate(maid: typeof(Maid.new()), _zone: ZoneConstants.Zone, zoneModel: Model)
    local sportsEquipments = CollectionService:GetTagged(SportsGamesConstants.Tag.SportsEquipment)
    for _, sportsEquipment in pairs(sportsEquipments) do
        if sportsEquipment:IsDescendantOf(zoneModel) then
            setupSportsEquipment(sportsEquipment, maid)
        end
    end
end

return SportsGameController
