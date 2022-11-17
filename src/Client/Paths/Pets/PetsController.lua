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
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Scope = require(Paths.Shared.Scope)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local ClientPet = require(Paths.Client.Pets.ClientPet)

local CHECK_HATCHABLE_EGGS_EVERY = 3
local EQUIPPED_PET_DATA_ADDRESS = "Pets.EquippedPetDataIndex"

local hatchRequestMaid = Maid.new()
local hatchRequestScope = Scope.new()

local petId: number | nil
local pet: ClientPet.ClientPet | nil

PetsController.PetNameChanged = Signal.new() -- { petName: string, petDataIndex: string }

function PetsController.Start()
    -- Routine for informing of eggs ready to hatch
    do
        -- Circular Dependencies
        local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)

        local informed: { [string]: { [string]: boolean } } = {} -- Keys are PetEggName, Values are arrays of petEggDataIndex
        UIUtil.waitForHudAndRoomZone():andThen(function()
            while true do
                -- Inform New
                local allHatchTimes = PetsController.getHatchTimes()
                for petEggName, hatchTimes in pairs(allHatchTimes) do
                    for petEggDataIndex, hatchTime in pairs(hatchTimes) do
                        local doInform = hatchTime == 0 and not (informed[petEggName] and informed[petEggName][petEggDataIndex])
                        if doInform then
                            informed[petEggName] = informed[petEggName] or {}
                            informed[petEggName][petEggDataIndex] = true

                            local product = ProductUtil.getPetEggProduct(petEggName)
                            UIActions.sendRobloxNotification({
                                Title = "Pet Egg",
                                Text = "You have a new Pet Egg you can hatch!",
                                Icon = product.ImageId or Images.Pets.Eggs.Standard,
                            })

                            local notificationIcon = UIActions.addNotificationIcon(HUDScreen.getInventoryButton():GetButtonObject())
                            notificationIcon:IncrementNumber(1)
                        end
                    end
                end

                -- Clear old informed
                for petEggName, petEggDataIndexes in pairs(informed) do
                    for petEggDataIndex, _ in pairs(petEggDataIndexes) do
                        if not (allHatchTimes[petEggName] and allHatchTimes[petEggName][petEggDataIndex]) then
                            informed[petEggName][petEggDataIndex] = nil

                            local notificationIcon = UIActions.getNotificationIcon(HUDScreen.getInventoryButton():GetButtonObject())
                            if notificationIcon then
                                notificationIcon:IncrementNumber(-1)
                            end
                        end
                    end
                end

                task.wait(CHECK_HATCHABLE_EGGS_EVERY)
            end
        end)
    end

    -- Communication
    Remotes.bindEvents({
        PetEggHatched = function(petData: PetConstants.PetData, petDataIndex: string)
            -- Circular Dependency
            local PetEggHatchingScreen = require(Paths.Client.UI.Screens.PetEggHatching.PetEggHatchingScreen)

            PetEggHatchingScreen:SetHatchedPetData(petData, petDataIndex)
        end,
        PetCreated = function(newPetId: number, petDataIndex: string)
            -- Cull Old
            if petId then
                petId = newPetId

                if pet then
                    pet:Destroy()
                end
            end
            petId = newPetId

            -- Create New
            local newPet = ClientPet.new(newPetId, petDataIndex) -- Yields while we get model
            if petId == newPetId then
                pet = newPet
            else
                newPet:Destroy()
            end
        end,
        PetDestroyed = function(oldPetId: number)
            -- Cull Old
            if petId == oldPetId then
                petId = nil

                if pet then
                    pet:Destroy()
                end
            end
        end,
    })
end

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

-- Returns PetDataIndex (if it exists)
function PetsController.getEquippedPetDataIndex()
    return DataController.get(EQUIPPED_PET_DATA_ADDRESS)
end

function PetsController.equipPetRequest(petDataIndex: string)
    Remotes.invokeServer("EquipRequest", petDataIndex)
end

function PetsController.unequipPetRequest()
    Remotes.invokeServer("EquipRequest", nil)
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

    local function request()
        UIController.getStateMachine():Push(UIConstants.States.PetEggHatching, {
            PetEggName = petEggName,
        })

        local didHatch = Remotes.invokeServer("PetEggHatchRequest", petEggName, petEggDataIndex)
        if not didHatch then
            UIController.getStateMachine():Remove(UIConstants.States.PetEggHatching)
        end
    end

    -- Premature.. wrap inside needing a quickHatch product
    if isPremature and ProductController.getProductCount(Products.Products.Misc.quick_hatch) == 0 then
        ProductController.prompt(Products.Products.Misc.quick_hatch)
        hatchRequestMaid:GiveTask(ProductController.ProductAdded:Connect(function(product: Products.Product)
            if product == Products.Products.Misc.quick_hatch then
                request()
            end
        end))
        return
    end

    request()
end

function PetsController.getTotalHatchableEggs()
    local total = 0
    for _, hatchTimes in pairs(PetsController.getHatchTimes()) do
        for _, hatchTime in pairs(hatchTimes) do
            if hatchTime == 0 then
                total += 1
            end
        end
    end

    return total
end

return PetsController
