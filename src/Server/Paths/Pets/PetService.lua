local PetService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local ProductService: typeof(require(Paths.Server.Products.ProductService))
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local SessionService = require(Paths.Server.SessionService)

function PetService.Init()
    -- Dependencies
    ProductService = require(Paths.Server.Products.ProductService)
end

--[[
    Will check that `player` has incubation data for all incubating pet egg products they own. If not, will instantiate it. Will also cull old hatch times.
]]
function PetService.updateIncubation(player: Player)
    local playtime = SessionService.getSession(player):GetPlayTime()

    -- Get Incubating Egg Totals
    local eggTotals: { [string]: number } = {}
    for petEggName, _petEgg in pairs(PetConstants.PetEggs) do
        eggTotals[petEggName] = ProductService.getProductCount(player, ProductUtil.getPetEggProduct(petEggName, "Incubating"))
    end

    -- Update Data
    local hatchTimeByEggsData: { [string]: { [string]: number } } = DataService.get(player, "Pets.Eggs")
    for petEggName, total in pairs(eggTotals) do
        local hatchTimes: { number } = hatchTimeByEggsData[petEggName] and TableUtil.toArray(hatchTimeByEggsData[petEggName]) or {}

        if total > #hatchTimes then -- Add Eggs
            for _ = 1, (total - #hatchTimes) do
                local hatchTime = PetConstants.PetEggs[petEggName].HatchTime + playtime -- Offset with `playtime` as `PetService.getHatchTimes` deducts current playtime
                table.insert(hatchTimes, hatchTime)
            end

            hatchTimeByEggsData[petEggName] = TableUtil.toDictionary(hatchTimes)
        elseif total < #hatchTimes then -- Remove Eggs
            -- Remove lowest hatch times
            table.sort(hatchTimes)
            for _ = 1, (#hatchTimes - total) do
                table.remove(hatchTimes, 1)
            end

            if #hatchTimes == 0 then
                hatchTimeByEggsData[petEggName] = nil
            else
                hatchTimeByEggsData[petEggName] = TableUtil.toDictionary(hatchTimes)
            end
        else -- Nothing to change
            return
        end
    end

    DataService.set(player, "Pets.Eggs", hatchTimeByEggsData, "PetEggsUpdated")
end

--[[
    Returns the current hatch times for a players' eggs at this exact point in time.

    `{ [petEggName]: { hatchTime } }`
]]
function PetService.getHatchTimes(player: Player)
    local playtime = SessionService.getSession(player):GetPlayTime()
    local hatchTimeByEggsData: { [string]: { [string]: number } } = DataService.get(player, "Pets.Eggs")

    local allHatchTimes: { [string]: { number } } = {}
    for petEggName, _petEgg in pairs(PetConstants.PetEggs) do
        local hatchTimes: { number } = hatchTimeByEggsData[petEggName] and TableUtil.toArray(hatchTimeByEggsData[petEggName])
        if hatchTimes then
            hatchTimes = TableUtil.mapValues(hatchTimes, function(hatchTime: number)
                return math.clamp(hatchTime - playtime, 0, math.huge)
            end)
            allHatchTimes[petEggName] = hatchTimes
        end
    end

    return allHatchTimes
end

function PetService.loadPlayer(player: Player)
    PetService.updateIncubation(player)
end

function PetService.unloadPlayer(player: Player)
    PetService.updateIncubation(player)

    -- Deduct playtime from egg hatch times
    local currentHatchTimes = PetService.getHatchTimes(player)
    local hatchTimeByEggsData: { [string]: { [string]: number } } = {}
    for petEggName, hatchTimes in pairs(currentHatchTimes) do
        hatchTimeByEggsData[petEggName] = TableUtil.toDictionary(hatchTimes)
    end
    DataService.set(player, "Pets.Eggs", hatchTimeByEggsData)
end

return PetService
