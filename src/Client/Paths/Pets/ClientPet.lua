local ClientPet = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Workspace = game:GetService("Workspace")
local Pet = require(Paths.Shared.Pets.Pet)
local PetMover = require(Paths.Client.Pets.PetMover)
local PetAnimator = require(Paths.Client.Pets.PetAnimator)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)

export type ClientPet = typeof(ClientPet.new())

local WAIT_FOR_MODEL_FOR = 10
local ANIMATION_PRIORITIES = {
    [PetConstants.AnimationNames.Idle] = 0,
    [PetConstants.AnimationNames.Trick] = 1,
    [PetConstants.AnimationNames.Sit] = 1,
    [PetConstants.AnimationNames.Walk] = 2,
    [PetConstants.AnimationNames.Jump] = 3,
}

local petsFolder = Workspace:WaitForChild("PetModels")

function ClientPet.new(petId: number, petDataIndex: string)
    local clientPet = Pet.new(Players.LocalPlayer)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local model: Model = petsFolder:WaitForChild(tostring(petId), WAIT_FOR_MODEL_FOR)
    local petMover: PetMover.PetMover
    local runningAnimations: { [string]: boolean } = {}
    local currentAnimationPlaying: string

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function updateAnimation(animationName: string, doPlay: boolean)
        -- Write into running animations (disabling any with the same priority)
        local priority = ANIMATION_PRIORITIES[animationName]
        for someAnimationName, _ in pairs(runningAnimations) do
            local somePriority = ANIMATION_PRIORITIES[someAnimationName]
            if somePriority == priority then
                runningAnimations[someAnimationName] = nil
            end
        end
        runningAnimations[animationName] = doPlay or nil

        -- Decide what animation is playing
        local newAnimationPlaying: string
        for someAnimationName, _ in pairs(runningAnimations) do
            local somePriority = ANIMATION_PRIORITIES[someAnimationName]
            if not newAnimationPlaying or somePriority > ANIMATION_PRIORITIES[newAnimationPlaying] then
                newAnimationPlaying = someAnimationName
            end
        end
        newAnimationPlaying = newAnimationPlaying or PetConstants.AnimationNames.Idle

        if newAnimationPlaying ~= currentAnimationPlaying then
            currentAnimationPlaying = newAnimationPlaying
        end
    end

    local function setup()
        local didLoad = ZoneUtil.waitForInstanceToLoad(model)
        if didLoad then
            -- Pet Follower
            petMover = PetMover.new(model)
            clientPet:GetMaid():GiveTask(petMover)

            -- Have mover state inform animation
            clientPet:GetMaid():GiveTask(petMover.StateChanged:Connect(function(state)
                if state == "Idle" then
                    updateAnimation(PetConstants.AnimationNames.Idle, true)
                    updateAnimation(PetConstants.AnimationNames.Walk, false)
                    updateAnimation(PetConstants.AnimationNames.Jump, false)
                elseif state == "Walking" then
                    updateAnimation(PetConstants.AnimationNames.Walk, true)
                    updateAnimation(PetConstants.AnimationNames.Jump, false)
                elseif state == "Jumping" then
                    updateAnimation(PetConstants.AnimationNames.Jump, true)
                else
                    error(("Missing edgecase for state %q"):format(state))
                end

                PetAnimator.playAnimation(clientPet:GetId(), currentAnimationPlaying, true)
            end))
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function clientPet:PlayAnimation(animationName: string)
        -- ERROR: Bad animation name
        if not ANIMATION_PRIORITIES[animationName] then
            error(("Bad animationName %q"):format(animationName))
        end

        updateAnimation(animationName, true)
        PetAnimator.playAnimation(clientPet:GetId(), currentAnimationPlaying, true)
    end

    function clientPet:StopAnimation(animationName: string)
        -- ERROR: Bad animation name
        if not ANIMATION_PRIORITIES[animationName] then
            error(("Bad animationName %q"):format(animationName))
        end

        updateAnimation(animationName, false)
        PetAnimator.playAnimation(clientPet:GetId(), currentAnimationPlaying, true)
    end

    function clientPet:GetPetDataIndex()
        return petDataIndex
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    clientPet:SetId(petId)

    if model then
        setup()
    else
        warn("ree no pet model")
    end

    clientPet:PlayAnimation(PetConstants.AnimationNames.Idle)

    return clientPet
end

return ClientPet
