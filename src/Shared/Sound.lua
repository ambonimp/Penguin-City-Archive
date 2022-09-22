local Sound = {}

local SoundService = game:GetService("SoundService")

local soundsByName: { [string]: Sound } = {}

local function getSound(soundName: string)
    local sound = soundsByName[soundName]
    if not sound then
        error(("No sound %q"):format(soundName))
    end

    return sound
end

-- Plays sound globally. Plays by using `PlayOnRemove`, unless specified otherwise
function Sound.play(soundName: string, dontRemove: boolean?): Sound | nil
    local sound = getSound(soundName):Clone()
    sound.Parent = game.Workspace

    if dontRemove then
        sound:Play()
        return sound
    end

    sound.PlayOnRemove = true
    sound:Destroy()
end

-- Load Sounds
do
    for _, soundFolder in pairs(SoundService:GetChildren()) do
        -- ERROR: No sound group
        local soundGroup = soundFolder:FindFirstChildOfClass("SoundGroup")
        if not soundGroup then
            error(("SoundFolder %s has no SoundGroup"):format(soundFolder:GetFullName()))
        end

        for _, sound: Sound in pairs(soundFolder:GetChildren()) do
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
