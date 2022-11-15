local InventoryPetsWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local InventoryWindow = require(Paths.Client.UI.Screens.Inventory.InventoryWindow)
local PetsController = require(Paths.Client.Pets.PetsController)

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
    for _, petData in pairs(petDatas) do
        -- Create Entry
        local entry = {
            WidgetConstructor = function()
                local widget = Widget.diverseWidgetFromPetData(petData)
                return widget
            end,
        }
        table.insert(populateData, entry)
    end

    inventoryPetsWindow:Populate(populateData)

    return inventoryPetsWindow
end

return InventoryPetsWindow
