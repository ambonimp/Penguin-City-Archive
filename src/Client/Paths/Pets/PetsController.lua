local PetsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SessionController = require(Paths.Client.SessionController)
local DataController = require(Paths.Client.DataController)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PetUtils = require(Paths.Shared.Pets.PetUtils)

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

local function getHatchTimeByEggsData()
    return DataController.get("Pets.Eggs") :: { [string]: { [string]: number } }
end

--[[
    Returns the current hatch times for our eggs at this exact point in time (where hatchTimes are sorted smallest to largest)

    `{ [petEggName]: { [petEggIndex]: hatchTime } }`
]]
function PetsController.getHatchTimes(ignorePlaytime: boolean?)
    local playtime = ignorePlaytime and 0 or SessionController.getSession():GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData()
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

function PetsController.getHatchTime(petEggName: string, petEggIndex: string, ignorePlaytime: boolean?)
    local hatchTimes = PetsController.getHatchTimes(ignorePlaytime)
    return hatchTimes[petEggName] and hatchTimes[petEggName][petEggIndex] or -1
end

return PetsController
