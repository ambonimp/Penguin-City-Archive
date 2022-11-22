--[[
    Nice selection of effects that return a cleanup function
]]
local Effects = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = require(ReplicatedStorage.Shared.Particles)
local Sound = require(ReplicatedStorage.Shared.Sound)
local CharacterUtil = require(ReplicatedStorage.Shared.Utils.CharacterUtil)

local blankPart = Instance.new("Part")

function Effects.getCharacterAdornee(player: Player): Part
    return CharacterUtil.getHumanoidRootPart(player) or blankPart
end

function Effects.coins(adornee: Instance, duration: number?)
    local particle = Particles.play("Coins", adornee)
    local sound = Sound.play("Coins", true, adornee)

    local isCleaning = false
    local function cleanup()
        if isCleaning then
            return
        end
        isCleaning = true

        Particles.remove(particle)
        Sound.fadeOut(sound)
    end

    if duration then
        task.delay(duration, cleanup)
    end

    return cleanup
end

return Effects
