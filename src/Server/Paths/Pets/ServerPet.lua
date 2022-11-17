local ServerPet = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Pet = require(Paths.Shared.Pets.Pet)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

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
    serverPet:GetMaid():GiveTask(model)

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setupModel()
        -- Anchor + Disable collisions
        local baseParts = InstanceUtil.getChildren(model, function(child)
            return child:IsA("BasePart")
        end)
        for _, basePart: BasePart in pairs(baseParts) do
            basePart.Anchored = true
            basePart.CanCollide = false
        end

        -- Name + Parent
        model.Name = tostring(serverPet:GetId())
        model.Parent = petsFolder

        -- Position + Give client ownership
        local character = owner.Character
        if character then
            model:PivotTo(character:GetPivot())

            model.PrimaryPart:SetNetworkOwner(owner)
            owner:RequestStreamAroundAsync(model:GetPivot().Position)
        else
            error(("No player Character (%s)"):format(owner.Name))
        end
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
