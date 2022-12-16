--[[
    Nice Util for using ReplicatedStorage.Assets.Particles
]]
local Particles = {}

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollisionsConstants = require(ReplicatedStorage.Shared.Constants.CollisionsConstants)

function Particles.get(particleName: string)
    local particle: ParticleEmitter | Folder = ReplicatedStorage.Assets.Particles:FindFirstChild(particleName)
    if not particle then
        error(("No particle %q"):format(particleName))
    end

    local emitters: { ParticleEmitter } = {}
    if particle:IsA("Folder") then
        for _, emitter in pairs(particle:GetChildren()) do
            if emitter:IsA("ParticleEmitter") then
                table.insert(emitters, emitter:Clone())
            end
        end
    elseif particle:IsA("ParticleEmitter") then
        emitters = { particle:Clone() }
    else
        error(("Unexpected class %s %q"):format(particle:GetFullName(), particle.ClassName))
    end

    return emitters
end

function Particles.play(particleName: string, adornee: Instance)
    local particles = Particles.get(particleName)
    for _, particle in pairs(particles) do
        particle.Enabled = true
        particle.Parent = adornee
    end

    return particles
end

-- Returns particles, and the adornee created for this
function Particles.playAtPosition(particleName: string, position: Vector3, size: Vector3?)
    local adornee = Instance.new("Part")
    adornee.Size = size or Vector3.new(1, 1, 1)
    adornee.Position = position
    adornee.Transparency = 1
    adornee.CanCollide = false
    adornee.Anchored = true
    adornee.Parent = game.Workspace
    PhysicsService:SetPartCollisionGroup(adornee, CollisionsConstants.Groups.Nothing)

    return Particles.play(particleName, adornee), adornee
end

-- Destroys the particle after disabling it and waiting its maximum lifetime. Optionally pass the adornee to get rid of that too!
function Particles.remove(particleOrParticles: ParticleEmitter | { ParticleEmitter }, adornee: BasePart?)
    local particles = typeof(particleOrParticles) == "table" and particleOrParticles or { particleOrParticles }

    for _, particle in pairs(particles) do
        particle.Enabled = false
        task.delay(particle.Lifetime.Max, function()
            particle:Destroy()
            if adornee then
                adornee:Destroy()
            end
        end)
    end
end

return Particles
