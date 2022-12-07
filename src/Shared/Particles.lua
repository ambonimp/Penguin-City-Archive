--[[
    Nice Util for using ReplicatedStorage.Assets.Particles
]]
local Particles = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- Destroys the particle after disabling it and waiting its maximum lifetime
function Particles.remove(particleOrParticles: ParticleEmitter | { ParticleEmitter })
    local particles = typeof(particleOrParticles) == "table" and particleOrParticles or { particleOrParticles }

    for _, particle in pairs(particles) do
        particle.Enabled = false
        task.delay(particle.Lifetime.Max, function()
            particle:Destroy()
        end)
    end
end

return Particles
