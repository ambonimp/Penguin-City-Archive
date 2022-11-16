local PetsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SessionController = require(Paths.Client.SessionController)
local DataController = require(Paths.Client.DataController)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local ProductController = require(Paths.Client.ProductController)
local Products = require(Paths.Shared.Products.Products)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local UIActions = require(Paths.Client.UI.UIActions)
local Images = require(Paths.Shared.Images.Images)
local Widget = require(Paths.Client.UI.Elements.Widget)
local Signal = require(Paths.Shared.Signal)
local Assume = require(Paths.Shared.Assume)

local hatchRequestMaid = Maid.new()

PetsController.PetNameChanged = Signal.new() -- { petName: string, petDataIndex: string }

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

-- Keys are petDataIndex
function PetsController.getPets()
    return DataController.get("Pets.Pets") :: { [string]: PetConstants.PetData }
end

function PetsController.getPet(petDataIndex: string)
    local petData = PetsController.getPets()[petDataIndex]
    if not petData then
        error(("No pet under index %q"):format(petDataIndex))
    end

    return petData
end

-- Assumes `petName` has been filtered
function PetsController.setPetName(petName: string, petDataIndex: string)
    local oldName = PetsController.getPet(petDataIndex)

    local assume = Assume.new(function()
        return Remotes.invokeServer("ChangePetName", petName, petDataIndex)
    end)
    assume:Check(function(response)
        return response == true
    end)
    assume:Run(function()
        PetsController.PetNameChanged:Fire(petName, petDataIndex)
    end)
    assume:Else(function()
        PetsController.PetNameChanged:Fire(oldName, petDataIndex)
    end)

    return assume
end

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

local function getHatchTimeByEggsData()
    return DataController.get("Pets.Eggs") :: { [string]: { [string]: number } }
end

--[[
    Returns the current hatch times for our eggs at this exact point in time (where hatchTimes are sorted smallest to largest)

    `{ [petEggName]: { [petEggDataIndex]: hatchTime } }`
]]
function PetsController.getHatchTimes(ignorePlaytime: boolean?)
    local playtime = ignorePlaytime and 0 or SessionController.getSession():GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData()
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

function PetsController.getHatchTime(petEggName: string, petEggDataIndex: string, ignorePlaytime: boolean?)
    local hatchTimes = PetsController.getHatchTimes(ignorePlaytime)
    return hatchTimes[petEggName] and hatchTimes[petEggName][petEggDataIndex] or -1
end

function PetsController.hatchRequest(petEggName: string, petEggDataIndex: string, isPremature: boolean?)
    hatchRequestMaid:Cleanup()

    local function requestServer()
        Remotes.invokeServer("PetEggHatchRequest", petEggName, petEggDataIndex) -- todo use an Assume here
    end

    -- Premature.. wrap inside needing a quickHatch product
    if isPremature and ProductController.getProductCount(Products.Products.Misc.quick_hatch) == 0 then
        ProductController.prompt(Products.Products.Misc.quick_hatch)
        hatchRequestMaid:GiveTask(ProductController.ProductAdded:Connect(function(product: Products.Product)
            if product == Products.Products.Misc.quick_hatch then
                requestServer()
            end
        end))
        return
    end

    requestServer()
end

-------------------------------------------------------------------------------
-- Communication
-------------------------------------------------------------------------------

Remotes.bindEvents({
    PetEggHatched = function(petData: PetConstants.PetData)
        print("hatched", petData)
        UIActions.prompt("CONGRATULATIONS", "You just hatched a new pet!", function(parent, maid)
            local petWidget = Widget.diverseWidgetFromPetData(petData)
            petWidget:Mount(parent, true)
            maid:GiveTask(petWidget)
        end, { Text = "Continue" }, { Text = "View Pet" }, { Image = Images.Pets.Lightburst })
    end,
})

return PetsController
