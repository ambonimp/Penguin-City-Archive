--[[
    Nice selection of effects that return a cleanup function
]]
local Effects = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = require(ReplicatedStorage.Shared.Particles)
local Sound = require(ReplicatedStorage.Shared.Sound)
local CharacterUtil = require(ReplicatedStorage.Shared.Utils.CharacterUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local blankPart = Instance.new("Part")

local cleanups: { [Instance]: { [() -> ()]: true? } } = {}

function Effects.getCharacterAdornee(player: Player): Part
    return CharacterUtil.getHumanoidRootPart(player) or blankPart
end

function Effects.coins(adornee: Instance, duration: number?)
    local particles = Particles.play("Coins", adornee)
    local sound = Sound.play("Coins", true, adornee)

    local cleanupDelay: thread?
    local cleanup

    local adoorneeCleanups = cleanups[adornee] or {}
    cleanups[adornee] = adoorneeCleanups

    cleanup = function()
        if cleanupDelay then
            task.cancel(cleanupDelay)
        end

        Particles.remove(particles)
        Sound.fadeOut(sound)

        adoorneeCleanups[cleanup] = nil
        if TableUtil.length(adoorneeCleanups) == 0 then
            cleanups[adornee] = nil
        end
    end

    adoorneeCleanups[cleanup] = true
    cleanupDelay = task.delay(duration, function()
        cleanupDelay = nil
        cleanup()
    end)

    return cleanup
end

function Effects.clear(adornee: Instance)
    local adoorneeCleanups = cleanups[adornee]
    if adoorneeCleanups then
        for cleanup in pairs(adoorneeCleanups) do
            cleanup()
        end
    end
end

return Effects
