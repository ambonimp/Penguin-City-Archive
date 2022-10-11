local Sound = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)

local DEFAULT_FADE_DURATION = 0.5

local soundsByName: { [string]: Sound } = {}

local function getSound(soundName: string)
    local sound = soundsByName[soundName]
    if not sound then
        error(("No sound %q"):format(soundName))
    end

    return sound
end

-- Plays sound globally. Plays by using `PlayOnRemove`, or via :Play() and is not removed
function Sound.play(soundName: string, dontRemove: boolean?, parent: any?): Sound | nil
    local sound = getSound(soundName):Clone()
    sound.Parent = parent or game.Workspace

    if dontRemove then
        sound:Play()
        return sound
    end

    -- WARN: Is looped
    if sound.Looped then
        warn(("PlayOnRemove'd a looped sound (%s)"):format(soundName))
    end

    sound.PlayOnRemove = true
    sound:Destroy()
end

function Sound.fadeIn(sound: Sound, duration: number?)
    duration = duration or DEFAULT_FADE_DURATION

    local goalVolume = sound.Volume
    sound.Volume = 0

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    return TweenUtil.tween(sound, tweenInfo, { Volume = goalVolume })
end

function Sound.fadeOut(sound: Sound, duration: number?, destroyAfter: boolean?)
    duration = duration or DEFAULT_FADE_DURATION

    local tweenInfo = TweenInfo.new(duration or DEFAULT_FADE_DURATION, Enum.EasingStyle.Linear)
    local tween = TweenUtil.tween(sound, tweenInfo, { Volume = 0 })

    task.delay(duration, function()
        tween:Cancel()
        tween:Destroy()
        if destroyAfter then
            sound:Destroy()
        end
    end)

    return tween
end

-- Load Sounds
do
    for _, soundFolder in pairs(SoundService:GetChildren()) do
        -- ERROR: No sound group
        local soundGroup = soundFolder:FindFirstChildOfClass("SoundGroup")
        if not soundGroup then
            error(("SoundFolder %s has no SoundGroup"):format(soundFolder:GetFullName()))
        end

        for _, sound: Sound in pairs(soundFolder:GetDescendants()) do
            if sound:IsA("Sound") then
                -- ERROR: Duplicate name
                local soundName = sound.Name
                local duplicateSound = soundsByName[soundName]
                if duplicateSound then
                    error(("Duplicate Sounds (%s) (%s)"):format(duplicateSound:GetFullName(), sound:GetFullName()))
                end

                sound.SoundGroup = soundGroup
                soundsByName[soundName] = sound
            end
        end
    end
end

return Sound
