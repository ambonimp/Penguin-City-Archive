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

function PetsService.Init()
    -- Dependencies
    ProductService = require(Paths.Server.Products.ProductService)
end

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

-- Returns the PetDataIndex
function PetsService.addPet(player: Player, petData: PetConstants.PetData)
    petData.Name = petData.Name ~= "" and petData.Name
        or ("%s %s"):format(StringUtil.possessiveName(player.Name), StringUtil.getFriendlyString(petData.PetTuple.PetType))
    petData.BirthServerTime = petData.BirthServerTime or Workspace:GetServerTimeNow()

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

function PetsService.getPets(player: Player): { PetConstants.PetData }
    return TableUtil.toArray(DataService.get(player, "Pets.Pets"))
end

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

local function getHatchTimeByEggsData(player: Player)
    return DataService.get(player, "Pets.Eggs") :: { [string]: { [string]: number } }
end

--[[
    Will check that `player` has incubation data for all incubating pet egg products they own. If not, will instantiate it. Will also cull old hatch times.
]]
function PetsService.updateIncubation(player: Player)
    local playtime = SessionService.getSession(player):GetPlayTime()

    -- Get Incubating Egg Totals
    local eggTotals: { [string]: number } = {}
    for petEggName, _petEgg in pairs(PetConstants.PetEggs) do
        eggTotals[petEggName] = ProductService.getProductCount(player, ProductUtil.getPetEggProduct(petEggName, "Incubating"))
    end

    -- Update Data
    local hatchTimeByEggsData = getHatchTimeByEggsData(player)
    for petEggName, total in pairs(eggTotals) do
        local totalStoredTimes = hatchTimeByEggsData[petEggName] and TableUtil.length(hatchTimeByEggsData[petEggName]) or 0

        if total > totalStoredTimes then -- Add Eggs
            for i = 1, (total - totalStoredTimes) do
                local hatchTime = PetConstants.PetEggs[petEggName].HatchTime + playtime -- Offset with `playtime` as `PetsService.getHatchTimes` deducts current playtime

                local address = PetUtils.getPetEggDataAddress(petEggName)
                if totalStoredTimes == 0 and i == 1 then
                    DataService.set(player, address, {})
                end

                local appendKey = DataService.getAppendageKey(player, address)
                DataService.append(player, address, hatchTime, "PetEggUpdated", {
                    PetEggDataIndex = appendKey,
                    IsNewEgg = true,
                })
            end
        elseif hatchTimeByEggsData[petEggName] and total < totalStoredTimes then -- Remove Eggs
            -- Remove some hatch times
            for _ = 1, (totalStoredTimes - total) do
                for key, _ in pairs(hatchTimeByEggsData[petEggName]) do
                    local address = ("%s.%s"):format(PetUtils.getPetEggDataAddress(petEggName), key)
                    DataService.set(player, address, nil, "PetEggUpdated", {
                        PetEggDataIndex = key,
                    })
                    break
                end
            end
        else -- Nothing to change
            return
        end
    end
end

--[[
    Returns the current hatch times for a players' eggs at this exact point in time (taking into account players playtime)

    `{ [petEggName]: { [petEggDataIndex]: hatchTime } }`
]]
function PetsService.getHatchTimes(player: Player)
    local playtime = SessionService.getSession(player):GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData(player)
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

--[[
    Will set the hatch time for a pet egg to 0 (aka instantly hatch).

    - `ageIndex`: `1`: Lowest hatch time, `n`: nth lowest hatch time, `math.huge`: guarenteed oldest egg
]]
function PetsService.nukeEgg(player: Player, petEggName: string, petEggDataIndex: string)
    -- ERROR: Bad PetEggDataIndex
    local address = ("%s.%s"):format(PetUtils.getPetEggDataAddress(petEggName), petEggDataIndex)
    if not DataService.get(player, address) then
        error(("Bad PetEggDataIndex %s %q"):format(petEggName, petEggDataIndex))
    end

    DataService.set(player, address, 0, "PetEggUpdated", {
        PetEggDataIndex = petEggDataIndex,
    })
end

-------------------------------------------------------------------------------
-- Players
-------------------------------------------------------------------------------

function PetsService.loadPlayer(player: Player)
    PetsService.updateIncubation(player)
end

function PetsService.unloadPlayer(player: Player)
    PetsService.updateIncubation(player)

    -- Deduct playtime from egg hatch times data
    DataService.set(player, "Pets.Eggs", PetsService.getHatchTimes(player))
end

task.spawn(function()
    while task.wait(5) do
        for _, player in pairs(Players:GetPlayers()) do
            print(player, PetsService.getHatchTimes(player))
        end
    end
end)

return PetsService
