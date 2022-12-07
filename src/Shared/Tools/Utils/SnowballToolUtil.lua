local SnowballToolUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = require(ReplicatedStorage.Shared.Particles)

local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

function SnowballToolUtil.hideSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 1
end

function SnowballToolUtil.showSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 0
end

function SnowballToolUtil.matchSnowball(snowballModel: Model, oldSnowballModel: Model)
    snowballModel.PrimaryPart.Transparency = oldSnowballModel.PrimaryPart.Transparency
end

function SnowballToolUtil.highlight(snowballModel: Model)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = COLOR_WHITE
    highlight.OutlineColor = COLOR_WHITE
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.5
    highlight.Parent = snowballModel.PrimaryPart

    return highlight
end

function SnowballToolUtil.landingParticle(snowballModel: Model)
    local particles = Particles.play("SnowballLanding", snowballModel.PrimaryPart)
    for _, particle in pairs(particles) do
        particle.Color = ColorSequence.new(snowballModel.PrimaryPart.Color)
    end
    return particles
end

return SnowballToolUtil
