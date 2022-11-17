local Pet = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

local idCounter = 0

local function getNewId()
    idCounter += 1
    return idCounter
end

function Pet.new(owner: Player, petData: PetConstants.PetData)
    local pet = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    local name = petData.Name

    local id = getNewId()

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function pet:GetId()
        return id
    end

    function pet:SetId(newId: number)
        id = newId
    end

    function pet:GetOwner()
        return owner
    end

    function pet:GetMaid()
        return maid
    end

    function pet:UpdateName(newName: string)
        name = newName
    end

    function pet:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    --todo

    return pet
end

return Pet
