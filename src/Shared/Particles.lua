--[[
    Nice Util for using ReplicatedStorage.Assets.Particles
]]
local Particles = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

function Particles.get(particleName: string)
    local particle: ParticleEmitter = ReplicatedStorage.Assets.Particles:FindFirstChild(particleName)
    if not particle then
        error(("No particle %q"):format(particleName))
    end

    return particle:Clone() :: ParticleEmitter
end

function Particles.play(particleName: string, adornee: Instance)
    local particle = Particles.get(particleName)
    particle.Enabled = true
    particle.Parent = adornee

    return particle
end

-- Destroys the particle after disabling it and waiting its maximum lifetime
function Particles.remove(particle: ParticleEmitter)
    particle.Enabled = false
    task.delay(particle.Lifetime.Max, function()
        particle:Destroy()
    end)
end

return Particles
