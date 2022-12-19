local Pet = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Maid)

local idCounter = 0

local function getNewId()
    idCounter += 1
    return idCounter
end

function Pet.new(owner: Player)
    local pet = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    local id = getNewId()

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

    function pet:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    return pet
end

return Pet
