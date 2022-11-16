--[[
    Pets!

    PetEggs all have a hatch time associated to them - the value stored on our data profile is how long until that egg catches from the *start* of a
    players play session (see `unloadPlayer`)
]]
local PetsService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local ProductService: typeof(require(Paths.Server.Products.ProductService))
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local SessionService = require(Paths.Server.SessionService)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local Remotes = require(Paths.Shared.Remotes)
local Products = require(Paths.Shared.Products.Products)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local TextFilterUtil = require(Paths.Shared.Utils.TextFilterUtil)

function PetsService.Init()
    -- Dependencies
    ProductService = require(Paths.Server.Products.ProductService)
end

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

-- Returns the PetDataIndex
function PetsService.addPet(player: Player, petData: PetConstants.PetData)
    local appendKey = DataService.getAppendageKey(player, "Pets.Pets")
    DataService.append(player, "Pets.Pets", TableUtil.deepClone(petData), "PetUpdated", {
        PetDataIndex = appendKey,
    })
    return appendKey
end

function PetsService.removePet(player: Player, petDataIndex: string)
    local address = ("Pets.Pets.%s"):format(petDataIndex)
    DataService.set(player, address, nil, "PetUpdated", {
        PetDataIndex = petDataIndex,
    })
end

-- Keys are petDataIndex
function PetsService.getPets(player: Player)
    return DataService.get(player, "Pets.Pets") :: { [string]: PetConstants.PetData }
end

function PetsService.getPet(player: Player, petDataIndex: string)
    local petData = PetsService.getPets(player)[petDataIndex]
    if not petData then
        error(("No pet under index %q"):format(petDataIndex))
    end

    return petData
end

-- Returns true if successful.
function PetsService.changePetName(player: Player, petDataIndex: string, petName: string, doFilter: boolean?)
    -- (Filter) FALSE: Was filtered
    if doFilter then
        local filteredPetName = TextFilterUtil.filter(petName, player.UserId)
        local wasFiltered = not (filteredPetName and TextFilterUtil.wasFiltered(petName, filteredPetName) == false)
        if wasFiltered then
            return false
        else
            petName = filteredPetName
        end
    end

    -- ERROR: Bad pet data index
    local petData = PetsService.getPet(player, petDataIndex)
    if not petData then
        warn(("Bad PetDataIndex %q"):format(petDataIndex))
        return false
    end

    petData.Name = petName
    DataService.set(player, PetUtils.getPetDataAddress(petDataIndex), petData, "PetDataUpdated")

    return true
end

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

local function getHatchTimeByEggsData(player: Player)
    return DataService.get(player, "Pets.Eggs") :: { [string]: { [string]: number } }
end

-- Returns PetEggDataIndex
function PetsService.addPetEgg(player: Player, petEggName: string, hatchTime: number?)
    local playtime = SessionService.getSession(player):GetPlayTime()
    hatchTime = (hatchTime or PetConstants.PetEggs[petEggName].HatchTime) + playtime

    local address = PetUtils.getPetEggDataAddress(petEggName)
    local appendKey = DataService.getAppendageKey(player, address)
    DataService.append(player, address, hatchTime, "PetEggUpdated", {
        PetEggDataIndex = appendKey,
        IsNewEgg = true,
    })

    return appendKey
end

--[[
    Will set the hatch time for a pet egg
]]
function PetsService.setHatchTime(player: Player, petEggName: string, petEggDataIndex: string, hatchTime: number)
    -- ERROR: Bad PetEggDataIndex
    local address = ("%s.%s"):format(PetUtils.getPetEggDataAddress(petEggName), petEggDataIndex)
    if not DataService.get(player, address) then
        error(("Bad PetEggDataIndex %s %q"):format(petEggName, petEggDataIndex))
    end

    local playtime = SessionService.getSession(player):GetPlayTime()
    DataService.set(player, address, hatchTime + playtime, "PetEggUpdated", {
        PetEggDataIndex = petEggDataIndex,
    })
end

function PetsService.removePetEgg(player: Player, petEggName: string, petEggDataIndex: string)
    local address = ("%s.%s"):format(PetUtils.getPetEggDataAddress(petEggName), petEggDataIndex)
    DataService.set(player, address, nil, "PetEggUpdated", {
        PetEggDataIndex = petEggDataIndex,
    })
end

--[[
    Will hatch an egg for a player and run all necessary routines.

    If `petEggDataIndex` is passed, will wipe it form our data
]]
function PetsService.hatchEgg(player: Player, petEggName: string, petEggDataIndex: string?)
    -- Clear Data
    if petEggDataIndex then
        PetsService.removePetEgg(player, petEggName, petEggDataIndex)
    end

    -- Create + Add Pet
    local petTuple = PetUtils.rollEggForPetTuple(petEggName)
    local petData: PetConstants.PetData = {
        PetTuple = petTuple,
        Name = ("%s %s"):format(StringUtil.possessiveName(player.Name), StringUtil.getFriendlyString(petTuple.PetType)),
        BirthServerTime = Workspace:GetServerTimeNow(),
    }
    PetsService.addPet(player, petData)

    -- Inform Client
    Remotes.fireClient(player, "PetEggHatched", petData)
end
Remotes.declareEvent("PetEggHatched")

--[[
    Returns the current hatch times for a players' eggs at this exact point in time (taking into account players playtime)

    `{ [petEggName]: { [petEggDataIndex]: hatchTime } }`
]]
function PetsService.getHatchTimes(player: Player, ignorePlaytime: boolean?)
    local playtime = ignorePlaytime and 0 or SessionService.getSession(player):GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData(player)
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

function PetsService.getHatchTime(player: Player, petEggName: string, petEggDataIndex: string, ignorePlaytime: boolean?)
    local hatchTimes = PetsService.getHatchTimes(player, ignorePlaytime)
    return hatchTimes[petEggName] and hatchTimes[petEggName][petEggDataIndex] or -1
end

-------------------------------------------------------------------------------
-- Players
-------------------------------------------------------------------------------

function PetsService.unloadPlayer(player: Player)
    -- Deduct playtime from egg hatch times data
    DataService.set(player, "Pets.Eggs", PetsService.getHatchTimes(player))
end

-------------------------------------------------------------------------------
-- Communication
-------------------------------------------------------------------------------

Remotes.bindFunctions({
    PetEggHatchRequest = function(player: Player, dirtyPetEggName: any, dirtyPetEggDataIndex: any)
        -- Clean Data
        local petEggName = typeof(dirtyPetEggName) == "string" and PetConstants.PetEggs[dirtyPetEggName] and dirtyPetEggName
        local petEggDataIndex = typeof(dirtyPetEggDataIndex) == "string" and dirtyPetEggDataIndex
        if not (petEggName and petEggDataIndex) then
            return false
        end

        local hatchTime = PetsService.getHatchTime(player, petEggName, petEggDataIndex)
        if hatchTime == 0 then
            PetsService.hatchEgg(player, petEggName, petEggDataIndex)
            return true
        elseif hatchTime > 0 and ProductService.getProductCount(player, Products.Products.Misc.quick_hatch) > 0 then
            ProductService.addProduct(player, Products.Products.Misc.quick_hatch, -1)
            PetsService.hatchEgg(player, petEggName, petEggDataIndex)
            return true
        end

        return false
    end,
    ChangePetName = function(player: Player, dirtyPetName: any, dirtyPetDataIndex: any)
        -- Clean Data
        local petName = TypeUtil.toString(dirtyPetName)
        local petDataIndex = TypeUtil.toString(dirtyPetDataIndex)
        if not (petName and petDataIndex) then
            return false
        end

        -- FALSE: Bad petDataIndex
        local petData = PetsService.getPets(player)[petDataIndex]
        if not petData then
            return false
        end

        return PetsService.changePetName(player, petDataIndex, petName, true)
    end,
})

return PetsService
