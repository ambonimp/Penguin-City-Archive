local ServerPet = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Pet = require(Paths.Shared.Pets.Pet)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CollisionsService = require(Paths.Server.CollisionsService)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)

export type ServerPet = typeof(ServerPet.new())

local petsFolder = Instance.new("Folder")
petsFolder.Name = "PetModels"
petsFolder.Parent = Workspace

function ServerPet.new(owner: Player, petDataIndex: string)
    -- Circular Dependency
    local PetsService = require(Paths.Server.Pets.PetsService)

    local petData = PetsService.getPet(owner, petDataIndex)
    local serverPet = Pet.new(owner, petData)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local model: Model = PetUtils.getModel(petData.PetTuple.PetType, petData.PetTuple.PetVariant):Clone()

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setupModel()
        PhysicsService:SetPartCollisionGroup(model.PrimaryPart, CollisionsConstants.Groups.Pet)
        serverPet:GetMaid():GiveTask(model)

        -- ERROR: No character
        local character = owner.Character
        if not character then
            error(("No player Character (%s)"):format(owner.Name))
            serverPet:Destroy()
        end

        -- Name + Parent
        model.Name = tostring(serverPet:GetId())
        model.Parent = petsFolder

        -- Position + Give client ownership
        model:PivotTo(character:GetPivot())
        model.PrimaryPart:SetNetworkOwner(owner)
        owner:RequestStreamAroundAsync(model:GetPivot().Position)
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function serverPet:GetPetDataIndex()
        return petDataIndex
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setupModel()

    return serverPet
end

return ServerPet
