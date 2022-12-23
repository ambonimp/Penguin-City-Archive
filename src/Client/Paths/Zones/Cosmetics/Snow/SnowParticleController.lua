local SnowParticleController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Shared.Maid)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Particles = require(Paths.Shared.Particles)

local SNOWY_ZONES = {
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Town),
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Neighborhood),
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.School),
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.SkiHill),
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Minigame, ZoneConstants.ZoneType.Minigame.SledRace),
    ZoneUtil.zone(ZoneConstants.ZoneCategory.Minigame, ZoneConstants.ZoneType.Minigame.IceCreamExtravaganza),
}
local SNOW_PART_PROPERTIES = {
    CanCollide = false,
    Anchored = true,
    CanQuery = false,
    Transparency = 1,
    Size = Vector3.new(100, 100, 100),
    Name = "SnowParticlePart",
}
local SNOW_PARTICLE_PROPERTIES = {
    Rate = 40,
}

local camera = Workspace.CurrentCamera

function SnowParticleController.onZoneUpdate(maid: Maid.Maid, zone: ZoneConstants.Zone, _zoneModel: Model)
    -- RETURN: Not a snowy zone!
    local isZoneSnowy = false
    for _, snowyZone in pairs(SNOWY_ZONES) do
        if ZoneUtil.zonesMatch(zone, snowyZone) then
            isZoneSnowy = true
            break
        end
    end
    if not isZoneSnowy then
        return
    end

    -- Create Snow part
    local snowPart = Instance.new("Part")
    InstanceUtil.setProperties(snowPart, SNOW_PART_PROPERTIES)
    snowPart.Parent = game.Workspace
    maid:GiveTask(snowPart)

    -- Keep ontop of local player
    maid:GiveTask(RunService.Heartbeat:Connect(function()
        snowPart:PivotTo(camera.CFrame)
    end))

    -- Particle
    local snowParticles = Particles.play("Snowfall", snowPart)
    for _, snowParticle in pairs(snowParticles) do
        InstanceUtil.setProperties(snowParticle, SNOW_PARTICLE_PROPERTIES)
        maid:GiveTask(snowParticle)
    end
end

return SnowParticleController
