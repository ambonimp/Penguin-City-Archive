local ClientPet = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Workspace = game:GetService("Workspace")
local Pet = require(Paths.Shared.Pets.Pet)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local PetFollower = require(Paths.Client.Pets.PetFollower)

export type ClientPet = typeof(ClientPet.new())

local WAIT_FOR_MODEL_FOR = 10

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
    local petFollower: PetFollower.PetFollower

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setupModel()
        -- Pet Follower
        petFollower = PetFollower.new(model)
        clientPet:GetMaid():GiveTask(petFollower)
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

    if model then
        setupModel()
    end

    return clientPet
end

return ClientPet
