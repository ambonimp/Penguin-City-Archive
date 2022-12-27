local CharacterEditorScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Shared.Maid)
local CharacterItemConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants)
local Promise = require(Paths.Packages.promise)
local Remotes = require(Paths.Shared.Remotes)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local CharacterPreview = require(Paths.Client.Character.CharacterPreview)
local DataController = require(Paths.Client.DataController)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ProductController = require(Paths.Client.ProductController)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local Snackbar = require(Paths.Client.UI.Elements.Snackbar)

export type EquippedItems = { string }

local CHARACTER_PREVIEW_CONFIG = {
    SubjectScale = 7,
    SubjectPosition = -0.2,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.CharacterEditor
local panel = SelectionPanel.new()
panel:SetAlignment("Right")
panel:SetSize(4)
panel:Mount(screen)
panel:GetContainer().Visible = false
local equipSlots: Frame = screen.EquipSlots
local bodyTypeList: Frame = screen.BodyTypes

local tabMaid = Maid.new()

local previewCharacter, previewMaid
local equippedItems: { [string]: EquippedItems } = {}
local bootCallbacks: { () -> any } = {}

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function updateAppearance(changes: { [string]: EquippedItems }): CharacterItemConstants.Appearance
    return CharacterItemUtil.applyAppearance(previewCharacter, changes)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
    for _, keyValuePair in pairs(TableUtil.sortFromProperty(CharacterItemConstants, "TabOrder")) do
        local categoryName: string = keyValuePair.Key
        local categoryConstants: CharacterItemConstants.Category = keyValuePair.Value

        if categoryName == "BodyType" then
            local equipped: string

            for itemKey, itemConstants in pairs(categoryConstants.Items) do
                local button = Paths.Templates.CharacterEditor.BodyType:Clone()
                button.Name = itemKey
                button.Parent = bodyTypeList
                button.BackgroundColor3 = UIConstants.Colors.Buttons.White
                button.LayoutOrder = itemConstants.LayoutOrder
                button.Icon.Image = itemConstants.Icon

                local function equip(doUpdateAppearance: boolean)
                    if equipped then
                        bodyTypeList[equipped].BackgroundColor3 = UIConstants.Colors.Buttons.White
                    end

                    equipped = itemKey

                    local equippedItem = { itemKey }
                    equippedItems.BodyType = equippedItem
                    if doUpdateAppearance then
                        updateAppearance({ BodyType = equippedItem })
                    end

                    button.BackgroundColor3 = UIConstants.Colors.Buttons.SelectedYellow
                end

                button.MouseButton1Down:Connect(function()
                    equip(true)
                end)

                table.insert(bootCallbacks, function()
                    if DataController.get("CharacterAppearance." .. categoryName)["1"] == itemKey then
                        equip(false)
                    end
                end)
            end
        else
            local canEquip: boolean = categoryConstants.MaxEquippables ~= 0
            local canUnequip: boolean = categoryConstants.CanUnequip
            local maxEquippables: number = categoryConstants.MaxEquippables
            local canMultiEquip: boolean = maxEquippables > 1

            -------------------------------------------------------------------------------
            -- Equipping
            -------------------------------------------------------------------------------
            local function unequipItem(itemKey: string, doNotUpdateAppearance: true?)
                table.remove(equippedItems[categoryName], table.find(equippedItems[categoryName], itemKey))
                if not doNotUpdateAppearance then
                    updateAppearance({ [categoryName] = equippedItems[categoryName] })
                end

                panel:SetWidgetSelected(categoryName, itemKey, false)
            end

            local function equipItem(itemKey: string, doNotUpdateAppearance: true?)
                if canMultiEquip then
                    if #equippedItems[categoryName] == maxEquippables then
                        Snackbar.info(("Can't equip more than %s %ss"):format(maxEquippables, categoryName))
                        return
                    end
                else
                    -- Appearance is updated when the new item is equipped, no point in updating it here
                    local equipped = equippedItems[categoryName][1]
                    if equipped then
                        unequipItem(equipped, true)
                    end
                end

                table.insert(equippedItems[categoryName], itemKey)
                if not doNotUpdateAppearance then
                    updateAppearance({ [categoryName] = equippedItems[categoryName] })
                end

                panel:SetWidgetSelected(categoryName, itemKey, true)
            end

            local function bulkEquip(equipping: EquippedItems, doNotUpdateAppearance: true?)
                for _, itemKey in pairs(equipping) do
                    equipItem(itemKey, doNotUpdateAppearance)
                end
            end

            -------------------------------------------------------------------------------
            -- Interface
            -------------------------------------------------------------------------------
            local function displayItem(itemKey: string)
                local itemConstants = categoryConstants.Items[itemKey]
                local product = ProductUtil.getCharacterItemProduct(categoryName, itemKey)

                -- RETURN: Product isn't owned and not for sale
                if panel:HasWidget(categoryName, itemKey) or not (itemConstants.ForSale or ProductController.hasProduct(product)) then
                    return
                end

                local slotTask

                panel:AddWidgetFromProduct(categoryName, itemKey, false, product, {
                    VerifyOwnership = true,
                    HideText = true,
                }, function()
                    if canEquip then
                        local isEquipped = table.find(equippedItems[categoryName], itemKey)
                        if canUnequip and isEquipped then
                            unequipItem(itemKey)
                        elseif not isEquipped then
                            equipItem(itemKey)
                        end
                    elseif categoryName == "Outfit" then
                        local changedItems = updateAppearance({ [categoryName] = { itemKey } })
                        for category, items in pairs(changedItems) do
                            for _, item in pairs(equippedItems[category]) do
                                panel:SetWidgetSelected(category, item, false)
                            end
                            for _, item in pairs(items) do
                                panel:SetWidgetSelected(category, item, true)
                            end
                        end

                        TableUtil.overwrite(equippedItems, changedItems)
                    end
                end, function(widget)
                    if canMultiEquip then
                        widget.SelectedChanged:Connect(function(selected)
                            if selected then
                                local unequipButton = ExitButton.new()
                                unequipButton.Pressed:Connect(function()
                                    unequipItem(itemKey)
                                end)

                                local slot = Widget.diverseWidgetFromProduct(product, { HideText = true })
                                slot:SetCornerButton(unequipButton)
                                slot:Mount(equipSlots)

                                slotTask = tabMaid:GiveTask(function()
                                    slot:Destroy()
                                    unequipButton:Destroy()

                                    slotTask = nil
                                end)
                            else
                                if slotTask then
                                    tabMaid:EndTask(slotTask)
                                end
                            end
                        end)
                    end
                end)
            end

            panel:AddTab(categoryName, categoryConstants.TabIcon)

            -- Display items
            for itemKey in pairs(categoryConstants.Items) do
                displayItem(itemKey)
            end

            -- Display items that aren't for sale when obtained
            ProductController.ProductAdded:Connect(function(product: Products.Product)
                -- RETURN: Product must e
                if product.Type ~= ProductConstants.ProductType.CharacterItem then
                    return
                end

                local metadata = product.Metadata
                if metadata.CategoryName == categoryName then
                    displayItem(metadata.ItemKey)
                end
            end)

            if canEquip then
                equippedItems[categoryName] = {}
                table.insert(bootCallbacks, function()
                    for i = #equippedItems[categoryName], 1, -1 do
                        unequipItem(equippedItems[categoryName][i], true)
                    end

                    bulkEquip(DataController.get("CharacterAppearance." .. categoryName) :: EquippedItems, true)
                end)
            end
        end
    end

    panel.TabChanged:Connect(function()
        tabMaid:Cleanup()
    end)
end

-- Register UIState
do
    local characterIsReady
    local canOpen = true

    local function boot(data)
        -- RETURN: Menu is already open
        if not canOpen then
            return
        end

        canOpen = false

        -- RETURN: No character
        local character: Model = player.Character
        if not character then
            uiStateMachine:Pop()
            return
        end

        -- Only open character editor when the player is on the floor
        local stateUpdateConnection: RBXScriptConnection
        characterIsReady = Promise.new(function(resolve, reject)
            local humanoid: Humanoid = character.Humanoid
            local function checkState()
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Seated then
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
                    state = humanoid:GetState()
                end

                if state == Enum.HumanoidStateType.Dead then
                    uiStateMachine:PopIfStateOnTop(UIConstants.States.CharacterEditor)
                    reject()
                elseif state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
                    resolve()
                end
            end

            checkState()
            stateUpdateConnection = humanoid.StateChanged:Connect(checkState)
        end):finally(function()
            character = player.Character
            if character then
                character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            end
            stateUpdateConnection:Disconnect()
        end)

        -- RETURN: Player no longer wants to open the editor
        local proceed = characterIsReady:await()
        if not proceed then
            return
        end

        previewCharacter, previewMaid = CharacterPreview.preview(CHARACTER_PREVIEW_CONFIG)

        -- Callbacks
        for _, bootCallback in pairs(bootCallbacks) do
            bootCallback()
        end

        if data.Tab then
            panel:OpenTab(data.Tab)
        end
    end

    local function maximize()
        ScreenUtil.inLeft(panel:GetContainer())
        ScreenUtil.inRight(bodyTypeList)
        ScreenUtil.inUp(equipSlots)
    end

    local function minimize()
        ScreenUtil.out(panel:GetContainer())
        ScreenUtil.out(equipSlots)
        ScreenUtil.out(bodyTypeList)
    end

    local function shutdown()
        local characterStatus = characterIsReady:getStatus()

        -- RETURN: Player no longer wants to open the editor
        if characterStatus ~= Promise.Status.Resolved then
            characterIsReady:Cancel()
            characterIsReady:Destroy()
        else
            local currentApperance = DataController.get("CharacterAppearance")

            --Were changes were made to the character's appearance?
            local appearanceChanges = {}
            for categoryName, items in pairs(equippedItems) do
                if not TableUtil.shallowEquals(currentApperance[categoryName], items) then
                    appearanceChanges[categoryName] = items
                end
            end

            if TableUtil.length(appearanceChanges) ~= 0 then
                -- If so, relay them to the server so they can be verified and applied
                Remotes.invokeServer("UpdateCharacterAppearance", appearanceChanges)
            end

            local character = player.Character
            if character then
                character.HumanoidRootPart.Anchored = false
            end

            previewMaid:Destroy()
        end

        canOpen = true
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.CharacterEditor, {
        Boot = boot,
        Shutdown = shutdown,
        Maximize = maximize,
        Minimize = minimize,
    })
end

-- Manipulate UIState
do
    panel.ClosePressed:Connect(function()
        uiStateMachine:Pop()
    end)
end

return CharacterEditorScreen
