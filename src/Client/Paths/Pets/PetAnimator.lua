local PetAnimator = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Workspace = game:GetService("Workspace")
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Remotes = require(Paths.Shared.Remotes)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local petsFolder = Workspace:WaitForChild("PetModels")
local tracksByPetId: { [number]: { [string]: AnimationTrack } } = {}

local JUMP_HEIGHT_OFFSET_MULTIPLIER = 3
local JUMP_HEIGHT_TWEEN_INFO = TweenInfo.new(0, Enum.EasingStyle.Linear)

--[[
    Call `replicate` when animating our ClientPet
]]
function PetAnimator.playAnimation(petId: number, animationName: string, replicate: boolean?)
    -- See if we have all of the required instances..!
    local model: Model = petsFolder:FindFirstChild(tostring(petId))
    if not model then
        return
    end

    local animationController = model:FindFirstChildOfClass("AnimationController")
    if not animationController then
        return
    end

    local animator = animationController:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    -- Get tracks / Init
    local tracks = tracksByPetId[petId]
    if not tracks then
        tracks = {}
        tracksByPetId[petId] = tracks

        -- Load all animations
        for _, animation: Animation in pairs(animator:GetChildren()) do
            if animation:IsA("Animation") then
                tracks[animation.Name] = animator:LoadAnimation(animation)
            end
        end

        InstanceUtil.onDestroyed(model, function()
            if tracksByPetId[petId] then
                for _, track in pairs(tracksByPetId[petId]) do
                    track:Destroy()
                end
                tracksByPetId[petId] = nil
            end
        end)
    end

    -- Get track
    local track = tracks[animationName]
    if not track then
        error(("Bad AnimationName %q"):format(animationName))
    end

    -- Play this track
    for _, someTrack in pairs(tracks) do
        if someTrack == track then
            someTrack:Play()
        else
            someTrack:Stop()
        end
    end

    --!! We have some unfortunate behaviour with the jump animations - we need to manually + hackily offset the pet's Nametag off the back of the jump animation
    if animationName == "Jump" then
        local billboardGui = model:FindFirstChildWhichIsA("BillboardGui", true)
        if billboardGui then
            local duration = track.Length
            local baseOffset = billboardGui.StudsOffset
            local goalOffset = baseOffset + Vector3.new(0, PetConstants.Following.JumpHeight * JUMP_HEIGHT_OFFSET_MULTIPLIER, 0)

            TweenUtil.run(function(jumpProgress)
                local heightAlpha = PetUtils.getHeightAlphaFromPetJumpProgress(jumpProgress)
                local offset = baseOffset:Lerp(goalOffset, heightAlpha)
                billboardGui.StudsOffset = offset
            end, TweenInfo.new(duration, JUMP_HEIGHT_TWEEN_INFO.EasingStyle, JUMP_HEIGHT_TWEEN_INFO.EasingDirection))
        end
    end

    -- Replicate
    if replicate then
        Remotes.fireServer("PlayPetAnimation", petId, animationName)
    end
end

-- Play other clients' animations
Remotes.bindEvents({
    PlayPetAnimation = function(petId: number, animationName: string)
        PetAnimator.playAnimation(petId, animationName)
    end,
})

return PetAnimator
