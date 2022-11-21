local ClientPet = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Workspace = game:GetService("Workspace")
local Pet = require(Paths.Shared.Pets.Pet)
local PetMover = require(Paths.Client.Pets.PetMover)
local PetAnimator = require(Paths.Client.Pets.PetAnimator)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

export type ClientPet = typeof(ClientPet.new())

local WAIT_FOR_MODEL_FOR = 10
local MOVER_STATE_TO_ANIMATION_NAME = {
    Idle = "Idle",
    Jumping = "Jump",
    Walking = "Walk",
}

local petsFolder = Workspace:WaitForChild("PetModels")

function ClientPet.new(petId: number, petDataIndex: string)
    -- Circular Dependency
    local PetsController = require(Paths.Client.Pets.PetsController)

    local petData = PetsController.getPet(petDataIndex)
    local clientPet = Pet.new(Players.LocalPlayer, petData)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local model: Model = petsFolder:WaitForChild(tostring(petId), WAIT_FOR_MODEL_FOR)
    local petMover: PetMover.PetMover

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setup()
        local didLoad = ZoneUtil.waitForInstanceToLoad(model)
        if didLoad then
            -- Pet Follower
            petMover = PetMover.new(petData, model)
            clientPet:GetMaid():GiveTask(petMover)

            -- Have mover state inform animation
            clientPet:GetMaid():GiveTask(petMover.StateChanged:Connect(function(state)
                PetAnimator.playAnimation(clientPet:GetId(), MOVER_STATE_TO_ANIMATION_NAME[state], true)
            end))
            PetAnimator.playAnimation(clientPet:GetId(), "Idle", true)
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function clientPet:GetPetDataIndex()
        return petDataIndex
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    clientPet:SetId(petId)

    if model then
        setup()
    end

    return clientPet
end

return ClientPet
