local PetController = {}

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
    Returns the current hatch times for our eggs at this exact point in time.

    `{ [petEggName]: { hatchTime } }`
]]
function PetController.getHatchTimes()
    local playtime = SessionController.getSession():GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData()
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

return PetController
