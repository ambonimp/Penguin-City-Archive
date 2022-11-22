local ServerPet = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Pet = require(Paths.Shared.Pets.Pet)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local Nametag = require(Paths.Shared.Nametag)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

export type ServerPet = typeof(ServerPet.new())

local petsFolder = Instance.new("Folder")
petsFolder.Name = "PetModels"
petsFolder.Parent = Workspace

function ServerPet.new(owner: Player, petDataIndex: string)
    -- Circular Dependency
    local PetService = require(Paths.Server.Pets.PetService)

    local petData = PetService.getPet(owner, petDataIndex)
    local serverPet = Pet.new(owner, petData)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local model: Model = PetUtils.getModel(petData.PetTuple.PetType, petData.PetTuple.PetVariant):Clone()

    local nametag = Nametag.new()
    serverPet:GetMaid():GiveTask(nametag)

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setup()
        PhysicsService:SetPartCollisionGroup(model.PrimaryPart, CollisionsConstants.Groups.Pet)
        serverPet:GetMaid():GiveTask(model)

        -- ERROR: No character
        local character = owner.Character
        if not character then
            error(("No player Character (%s)"):format(owner.Name))
            serverPet:Destroy()
        end

        -- Animations
        local animationController = Instance.new("AnimationController")
        animationController.Parent = model
        local animator = Instance.new("Animator")
        animator.Parent = animationController

        for _, animation in pairs(PetUtils.getAnimations(petData.PetTuple.PetType)) do
            animation:Clone().Parent = animator
        end

        -- Name + Parent
        model.Name = tostring(serverPet:GetId())
        ModelUtil.scale(model, PetConstants.ModelScale)
        model.Parent = petsFolder

        -- Position + Give client ownership
        model:PivotTo(character:GetPivot())
        model.PrimaryPart:SetNetworkOwner(owner)
        owner:RequestStreamAroundAsync(model:GetPivot().Position)

        -- Streaming Init
        ZoneUtil.writeBasepartTotals(model)

        -- Nametag
        nametag:Mount(model)
        nametag:SetName(petData.Name)
        serverPet:GetMaid():GiveTask(PetService.PetNameChanged:Connect(function(_player: Player, somePetDataIndex: string, petName: string)
            if petDataIndex == somePetDataIndex then
                nametag:SetName(petName)
            end
        end))
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function serverPet:GetPetDataIndex()
        return petDataIndex
    end

    function serverPet:GetPetData()
        return petData
    end

    function serverPet:GetModel()
        return model
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()

    return serverPet
end

return ServerPet
