local CharacterEditorScreen = {}
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
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

export type EquippedItems = { string }

local STANDUP_TIME = 0.1
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

local tabMaid = Maid.new()

local previewCharacter, previewMaid
local equippedItems: { [string]: EquippedItems } = {}

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
                    elseif categoryName == "Outfit" then
                        local changedItems = updateAppearance({ [categoryName] = { itemName } })
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
                        local slotTask
                        widget.SelectedChanged:Connect(function(selected)
                            if selected then
                                local unequipButton = ExitButton.new()
                                unequipButton.Pressed:Connect(function()
                                    unequipItem(itemName)
                                end)

                                local slot = Widget.diverseWidgetFromProduct(product, { HideText = true })
                                slot:SetCornerButton(unequipButton)
                                slot:Mount(equipSlots)

                                slotTask = tabMaid:GiveTask(function()
                                    slot:Destroy()
                                    unequipButton:Destroy()
                                end)
                            else
                                tabMaid:RemoveTask(slotTask)
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
                    task.wait(STANDUP_TIME) -- Give it time to stand up
                end

                if state == Enum.HumanoidStateType.Dead then
                    uiStateMachine:PopIfStateOnTop(UIConstants.States.CharacterEditor)
                    reject()
                    return
                elseif state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
                    resolve()
                    return
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

        if data.Tab then
            panel:OpenTab(data.Tab)
        end
    end

    local function maximize()
        ScreenUtil.inLeft(panel:GetContainer())
        ScreenUtil.inUp(equipSlots)
    end

    local function minimize()
        ScreenUtil.out(panel:GetContainer())
        ScreenUtil.out(equipSlots)
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
