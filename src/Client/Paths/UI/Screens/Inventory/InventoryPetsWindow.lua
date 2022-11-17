local InventoryPetsWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local InventoryWindow = require(Paths.Client.UI.Screens.Inventory.InventoryWindow)
local PetsController = require(Paths.Client.Pets.PetsController)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Maid = require(Paths.Packages.maid)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local Button = require(Paths.Client.UI.Elements.Button)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)

--[[
    data:
    - ProductType: What products to display
    - AddCallback: If passed, will create an "Add" button that will invoke AddCallback
]]
function InventoryPetsWindow.new(
    icon: string,
    title: string,
    data: {
        AddCallback: (() -> nil)?,
    }
)
    data = data or {}
    local inventoryPetsWindow = InventoryWindow.new(icon, title, {
        AddCallback = data.AddCallback,
        Equipping = {
            Equip = function(petDataIndex: string)
                PetsController.equipPetRequest(petDataIndex)
            end,
            Unequip = function(_product: Products.Product)
                PetsController.unequipPetRequest()
            end,
            StartEquipped = PetsController.getEquippedPetDataIndex(),
        },
    })

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Populate
    local populateData: { {
        WidgetConstructor: () -> typeof(Widget.diverseWidget()),
        EquipValue: any | nil,
    } } | { { _HatchTime: number? } } =
        {}

    -- Eggs
    for petEggName, hatchTimes in pairs(PetsController.getHatchTimes(true)) do
        for petEggDataIndex, hatchTime in pairs(hatchTimes) do
            -- Create Entry
            local entry = {
                WidgetConstructor = function()
                    local widget = Widget.diverseWidgetFromEgg(petEggName, petEggDataIndex)
                    widget.Pressed:Connect(function()
                        local currentHatchTime = PetsController.getHatchTime(petEggName, petEggDataIndex)
                        if currentHatchTime > 0 then
                            PetsController.hatchRequest(petEggName, petEggDataIndex, true)
                        elseif currentHatchTime == 0 then
                            PetsController.hatchRequest(petEggName, petEggDataIndex)
                        end
                    end)

                    return widget
                end,
                _HatchTime = hatchTime,
            }

            -- Insert shortest hatchtime at front
            local didInsert = false
            for index, someEntry in pairs(populateData) do
                if someEntry._HatchTime and hatchTime < someEntry._HatchTime then
                    table.insert(populateData, index, entry)
                    didInsert = true
                    break
                end
            end
            if not didInsert then
                table.insert(populateData, entry)
            end
        end
    end

    -- Pets
    local petDatas = PetsController.getPets()
    for petDataIndex, petData in pairs(petDatas) do
        -- Create Entry
        local entry = {
            WidgetConstructor = function()
                -- Edit Button
                local button = AnimatedButton.fromButton(Button.fromImage(Images.ButtonIcons.Pencil))
                button:SetPressAnimation()
                button:SetHoverAnimation(AnimatedButton.Animations.Nod)
                button.Pressed:Connect(function()
                    UIController.getStateMachine():Push(UIConstants.States.PetEditor, {
                        PetData = petData,
                        PetDataIndex = petDataIndex,
                    })
                end)

                -- Widget
                local widget = Widget.diverseWidgetFromPetData(petData)
                widget:SetCornerButton(button)

                return widget
            end,
            EquipValue = petDataIndex,
        }
        table.insert(populateData, entry)
    end

    inventoryPetsWindow:Populate(populateData)

    return inventoryPetsWindow
end

return InventoryPetsWindow
