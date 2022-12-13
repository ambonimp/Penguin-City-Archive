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
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local Sound = require(Paths.Shared.Sound)

local WAIT_FOR_NETWORK_OWNERSHIP_TIMEOUT = 3
local TWEEN_INFO_LOCAL_TO_SERVER = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

local localPlayer = Players.LocalPlayer

local function hasNetworkOwnershipOfSportsEquipment(sportsEquipment: BasePart | Model)
    for _, instance: BasePart in pairs(ArrayUtil.merge(sportsEquipment:GetDescendants(), { sportsEquipment })) do
        if instance:IsA("BasePart") then
            if NetworkOwnerUtil.getNetworkOwner(instance) == localPlayer then
                return true
            end
        end
    end

    return false
end

local function simulatePushEquipment(sportsEquipment: BasePart | Model, sportsEquipmentType: string)
    -- Create Local Equipment
    local localSportsEquipment = sportsEquipment:Clone()
    localSportsEquipment.Name = ("%s (Local)"):format(localSportsEquipment.Name)
    localSportsEquipment.Parent = sportsEquipment.Parent

    -- Hide Server
    local serverInstances = sportsEquipment:IsA("BasePart") and sportsEquipment or sportsEquipment:GetDescendants()
    InstanceUtil.hide(serverInstances)

    -- Push Local
    SportsGamesUtil.pushEquipment(localPlayer, sportsEquipmentType, localSportsEquipment)

    -- Yield until we get ownership / timeout
    local yieldUntil = tick() + WAIT_FOR_NETWORK_OWNERSHIP_TIMEOUT
    while tick() < yieldUntil do
        if hasNetworkOwnershipOfSportsEquipment(sportsEquipment) then
            break
        end
        task.wait()
    end

    -- Tween local version onto server version
    local startPivot = localSportsEquipment:GetPivot()
    TweenUtil.run(function(alpha)
        -- RETURN: No sports equipment! (e.g., streamed out)
        if not sportsEquipment then
            return
        end

        -- Tween
        local cframe = startPivot:Lerp(sportsEquipment:GetPivot(), alpha)
        localSportsEquipment:PivotTo(cframe)

        -- Revert
        if alpha == 1 then
            InstanceUtil.show(sportsEquipment)
            localSportsEquipment:Destroy()
        end
    end, TWEEN_INFO_LOCAL_TO_SERVER)
end

local function setupSportsEquipment(sportsEquipment: BasePart | Model, sportsEquipmentType: string, maid: typeof(Maid.new()))
    -- Kick it when we touch it
    maid:GiveTask(sportsEquipment.Touched:Connect(function(otherPart)
        -- RETURN: Not our local player
        local player = CharacterUtil.getPlayerFromCharacterPart(otherPart)
        if not (player and player == localPlayer) then
            return
        end

        -- RETURN: Touched very recently
        local isFree = Limiter.debounce("SportsGame", player, SportsGamesConstants.PlayerTouchDebounceTime)
        if not isFree then
            return
        end

        -- Apply Force locally
        SportsGamesUtil.pushEquipment(localPlayer, sportsEquipmentType, sportsEquipment)

        -- Audio Feedback
        Sound.play(SportsGamesUtil.getPushSoundName(sportsEquipmentType))

        -- If not owned yet, simulate a local version
        if not hasNetworkOwnershipOfSportsEquipment(sportsEquipment) then
            simulatePushEquipment(sportsEquipment, sportsEquipmentType)
        end
    end))
end

function SportsGameController.onZoneUpdate(maid: typeof(Maid.new()), _zone: ZoneConstants.Zone, zoneModel: Model)
    local sportsEquipments = CollectionService:GetTagged(SportsGamesConstants.Tag.SportsEquipment)
    for _, sportsEquipment in pairs(sportsEquipments) do
        local sportsEquipmentType = sportsEquipment:GetAttribute(SportsGamesConstants.Attribute.SportsEquipmentType)
        if sportsEquipment:IsDescendantOf(zoneModel) then
            setupSportsEquipment(sportsEquipment, sportsEquipmentType, maid)
        end
    end
end

return SportsGameController
