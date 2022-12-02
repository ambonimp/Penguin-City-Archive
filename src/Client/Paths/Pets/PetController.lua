local PetController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SessionController = require(Paths.Client.SessionController)
local DataController = require(Paths.Client.DataController)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local ProductController = require(Paths.Client.ProductController)
local Products = require(Paths.Shared.Products.Products)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local UIActions = require(Paths.Client.UI.UIActions)
local Images = require(Paths.Shared.Images.Images)
local Signal = require(Paths.Shared.Signal)
local Assume = require(Paths.Shared.Assume)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ClientPet = require(Paths.Client.Pets.ClientPet)

local CHECK_HATCHABLE_EGGS_EVERY = 3
local EQUIPPED_PET_DATA_ADDRESS = "Pets.EquippedPetDataIndex"

local hatchRequestMaid = Maid.new()

local petId: number | nil
local pet: ClientPet.ClientPet | nil
local cachedEquippedPetDataIndex: string | nil

PetController.PetNameChanged = Signal.new() -- { petName: string, petDataIndex: string }
PetController.PetUpdated = Signal.new() -- Added/Removed { petDataIndex: string }
PetController.PetEggUpdated = Signal.new() -- Added/Removed { petEggDataIndex: string, isNewEgg: boolean? }
PetController.PetCreated = Signal.new() -- { petDataIndex: string }
PetController.PetDestroyed = Signal.new() -- { petDataIndex: string }

function PetController.Start()
    -- Routine for informing of eggs ready to hatch by notifications
    do
        -- Circular Dependencies
        local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)

        local informedPetEggs: { [string]: { [string]: boolean } } = {} -- Keys are PetEggName, Values are arrays of petEggDataIndex
        UIUtil.waitForHudAndRoomZone():andThen(function()
            while true do
                -- Inform New
                local allHatchTimes = PetController.getHatchTimes()
                for petEggName, hatchTimes in pairs(allHatchTimes) do
                    for petEggDataIndex, hatchTime in pairs(hatchTimes) do
                        local doInform = hatchTime == 0
                            and not (informedPetEggs[petEggName] and informedPetEggs[petEggName][petEggDataIndex])
                        if doInform then
                            informedPetEggs[petEggName] = informedPetEggs[petEggName] or {}
                            informedPetEggs[petEggName][petEggDataIndex] = true

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

                -- Clear old informedPetEggs
                for petEggName, petEggDataIndexes in pairs(informedPetEggs) do
                    for petEggDataIndex, _ in pairs(petEggDataIndexes) do
                        if not (allHatchTimes[petEggName] and allHatchTimes[petEggName][petEggDataIndex]) then
                            informedPetEggs[petEggName][petEggDataIndex] = nil

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
                PetController.PetCreated:Fire(petDataIndex)
            else
                newPet:Destroy()
            end
        end,
        PetDestroyed = function(oldPetId: number)
            -- Cull Old
            if petId == oldPetId then
                petId = nil

                if pet then
                    PetController.PetDestroyed:Fire(pet:GetPetDataIndex())
                    pet:Destroy()
                end
            end
        end,
    })

    -- Catch Data Change Events
    DataController.Updated:Connect(function(event: string, _newValue: any, eventMeta: table)
        if event == "PetUpdated" then
            PetController.PetUpdated:Fire(eventMeta.PetDataIndex)
        elseif event == "PetEggUpdated" then
            PetController.PetEggUpdated:Fire(eventMeta.PetEggDataIndex, eventMeta.IsNewEgg)
        end
    end)

    -- Load up PetEggDisplays
    require(Paths.Client.Pets.PetEggDisplays)
end

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

-- Keys are petDataIndex
function PetController.getPets()
    return DataController.get("Pets.Pets") :: { [string]: PetConstants.PetData }
end

function PetController.getPet(petDataIndex: string)
    local petData = PetController.getPets()[petDataIndex]
    if not petData then
        error(("No pet under index %q"):format(petDataIndex))
    end

    return petData
end

-- Returns our current ClientPet (if it exists)
function PetController.getClientPet()
    return pet
end

-- Assumes `petName` has been filtered
function PetController.requestSetPetName(petName: string, petDataIndex: string)
    local oldName = PetController.getPet(petDataIndex)

    local assume = Assume.new(function()
        return Remotes.invokeServer("ChangePetName", petName, petDataIndex)
    end)
    assume:Check(function(response)
        return response == true
    end)
    assume:Run(function()
        PetController.PetNameChanged:Fire(petName, petDataIndex)
    end)
    assume:Else(function()
        PetController.PetNameChanged:Fire(oldName, petDataIndex)
    end)

    return assume
end

-- Returns PetDataIndex (if it exists) directly from our data
function PetController.getEquippedPetDataIndex()
    return DataController.get(EQUIPPED_PET_DATA_ADDRESS)
end

function PetController.getCachedEquippedPetDataIndex()
    return cachedEquippedPetDataIndex
end

-- Returns true if successful. Yields.
function PetController.equipPetRequest(petDataIndex: string)
    local assume = Assume.new(function()
        return Remotes.invokeServer("EquipRequest", petDataIndex)
    end)
    assume:Check(function(returnValue)
        return returnValue == true
    end)
    assume:Run(function()
        cachedEquippedPetDataIndex = petDataIndex
    end)
    assume:Else(function()
        cachedEquippedPetDataIndex = nil
    end)
end

-- Returns true if successful. Yields.
function PetController.unequipPetRequest()
    task.spawn(Remotes.invokeServer, "EquipRequest", nil)
    cachedEquippedPetDataIndex = nil
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
function PetController.getHatchTimes(ignorePlaytime: boolean?)
    local playtime = ignorePlaytime and 0 or SessionController.getSession():GetPlayTime()
    local hatchTimeByEggsData = getHatchTimeByEggsData()
    return PetUtils.getHatchTimes(hatchTimeByEggsData, playtime)
end

function PetController.getHatchTime(petEggName: string, petEggDataIndex: string, ignorePlaytime: boolean?)
    local hatchTimes = PetController.getHatchTimes(ignorePlaytime)
    return hatchTimes[petEggName] and hatchTimes[petEggName][petEggDataIndex] or -1
end

function PetController.hatchRequest(petEggName: string, petEggDataIndex: string, isPremature: boolean?)
    hatchRequestMaid:Cleanup()

    -- Premature.. use a quick hatch product to make it instantly hatchable
    if isPremature then
        if ProductController.getProductCount(Products.Products.Misc.quick_hatch) == 0 then
            -- Needs to purchase product first
            ProductController.prompt(Products.Products.Misc.quick_hatch)
            hatchRequestMaid:GiveTask(ProductController.ProductAdded:Connect(function(product: Products.Product)
                if product == Products.Products.Misc.quick_hatch then
                    Remotes.invokeServer("PetEggQuickHatchRequest", petEggName, petEggDataIndex)
                end
            end))
        else
            -- We have a product to use
            Remotes.invokeServer("PetEggQuickHatchRequest", petEggName, petEggDataIndex)
        end
        return
    end

    -- We can go for it!
    UIController.getStateMachine():Push(UIConstants.States.PetEggHatching, {
        PetEggName = petEggName,
    })

    local didHatch = Remotes.invokeServer("PetEggHatchRequest", petEggName, petEggDataIndex)
    if not didHatch then
        UIController.getStateMachine():Remove(UIConstants.States.PetEggHatching)
    end
end

function PetController.getTotalHatchableEggs()
    local total = 0
    for _, hatchTimes in pairs(PetController.getHatchTimes()) do
        for _, hatchTime in pairs(hatchTimes) do
            if hatchTime == 0 then
                total += 1
            end
        end
    end

    return total
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

cachedEquippedPetDataIndex = PetController.getEquippedPetDataIndex()

return PetController
