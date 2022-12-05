local CharacterEditorScreen = {}
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Janitor = require(Paths.Packages.janitor)
local CharacterItemConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local CharacterPreview = require(Paths.Client.Character.CharacterPreview)
local DataController = require(Paths.Client.DataController)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Widget = require(Paths.Client.UI.Elements.Widget)

export type EquippedItems = { string }

local CHARACTER_PREVIEW_CONFIG = {
    SubjectScale = 9,
    SubjectPosition = -0.2,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local screen: ScreenGui = Paths.UI.CharacterEditor
local panel = SelectionPanel.new()
panel:SetAlignment("Right")
panel:SetSize(4)
panel:Mount(screen)
local equipSlots: Frame = screen.EquipSlots

local sessionJanitor = Janitor.new()
local tabJanitor = Janitor.new()

local previewCharacter, previewMaid
local equippedItems: { [string]: EquippedItems } = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function updateAppearance(changes: { [string]: EquippedItems }): CharacterItemConstants.Appearance
    return CharacterItemUtil.applyAppearance(previewCharacter, changes)
end

for _, keyValuePair in pairs(TableUtil.sortFromProperty(CharacterItemConstants, "TabOrder")) do
    local categoryName: string = keyValuePair.Key
    local categoryConstants: CharacterItemConstants.Category = keyValuePair.Value

    if categoryName ~= "BodyType" then
        local canEquip: boolean = categoryConstants.MaxEquippables ~= 0
        local canUnequip: boolean = categoryConstants.CanUnequip
        local maxEquippables: number = categoryConstants.MaxEquippables
        local canMultiEquip: boolean = maxEquippables > 1

        -------------------------------------------------------------------------------
        -- Equipping
        -------------------------------------------------------------------------------
        local function unequipItem(itemName: string, doNotUpdateAppearance: true?)
            table.remove(equippedItems[categoryName], table.find(equippedItems[categoryName], itemName))
            if not doNotUpdateAppearance then
                updateAppearance({ [categoryName] = equippedItems[categoryName] })
            end

            panel:SetWidgetSelected(categoryName, itemName, false)
        end

        local function equipItem(itemName: string, doNotUpdateAppearance: true?)
            if canMultiEquip then
                if #equippedItems[categoryName] == maxEquippables then
                    return
                end
            else
                -- Appearance is updated when the new item is equipped, no point in updating it here
                local equipped = equippedItems[categoryName][1]
                if equipped then
                    unequipItem(equipped, true)
                end
            end

            table.insert(equippedItems[categoryName], itemName)
            if not doNotUpdateAppearance then
                updateAppearance({ [categoryName] = equippedItems[categoryName] })
            end

            panel:SetWidgetSelected(categoryName, itemName, true)
        end

        local function bulkEquip(equipping: EquippedItems, doNotUpdateAppearance: true?)
            for _, itemName in pairs(equipping) do
                equipItem(itemName, doNotUpdateAppearance)
            end
        end

        -------------------------------------------------------------------------------
        -- Interface
        -------------------------------------------------------------------------------
        panel:AddTab(categoryName, categoryConstants.TabIcon)
        for itemName in pairs(categoryConstants.Items) do
            local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)

            panel:AddWidgetFromProduct(categoryName, itemName, false, product, {
                VerifyOwnership = true,
                HideText = true,
            }, function()
                if canEquip then
                    local isEquipped = table.find(equippedItems[categoryName], itemName)
                    if canUnequip and isEquipped then
                        unequipItem(itemName)
                    elseif not isEquipped then
                        equipItem(itemName)
                    end
                else
                    equippedItems = updateAppearance({ [categoryName] = { itemName } })
                end
            end, function(widget)
                if canMultiEquip then
                    local slotTask = itemName .. "Slot"
                    widget.SelectedChanged:Connect(function(selected)
                        if selected then
                            local unequipButton = ExitButton.new()
                            unequipButton.Pressed:Connect(function()
                                unequipItem(itemName)
                            end)

                            local slot = Widget.diverseWidgetFromProduct(product, { HideText = true })
                            slot:SetCornerButton(unequipButton)
                            slot:Mount(equipSlots)

                            tabJanitor:Add(function()
                                slot:Destroy()
                                unequipButton:Destroy()
                            end, nil, slotTask)
                        else
                            tabJanitor:Remove(slotTask)
                        end
                    end)
                end
            end)
        end

        if canEquip then
            equippedItems[categoryName] = {}
            bulkEquip(DataController.get("CharacterAppearance." .. categoryName) :: EquippedItems, true)
        end
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
panel.TabChanged:Connect(function()
    tabJanitor:Cleanup()
end)

local function open()
    ScreenUtil.inLeft(panel:GetContainer())
    ScreenUtil.inUp(equipSlots)

    previewCharacter, previewMaid = CharacterPreview.preview(CHARACTER_PREVIEW_CONFIG)
    sessionJanitor:Add(previewMaid)
end

open()

return CharacterEditorScreen
