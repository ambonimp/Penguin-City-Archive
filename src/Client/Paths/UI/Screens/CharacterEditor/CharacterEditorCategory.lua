local CharacterEditorCategory = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local DataController = require(Paths.Client.DataController)
local Button = require(Paths.Client.UI.Elements.Button)

type EquippedItems = { string }

local templates: Folder = Paths.Templates.CharacterEditor
local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Edit
local tabs: Frame = menu.Tabs
local selectedTab: Frame = tabs.SelectedTab

function CharacterEditorCategory.new(categoryName: string)
    local category = {}

    local preview: Model?
    local equippedItems: EquippedItems = {}

    local constants = CharacterItems[categoryName]
    local itemCount: number = TableUtil.length(constants.Items)
    local itemsOwned: { [string]: any } = DataController.get("Inventory." .. constants.InventoryPath)
    local multiEquip: boolean = constants.MaxEquippables ~= 1

    local page: Frame = templates.CategoryPage:Clone()
    page.Name = categoryName
    page.Visible = false
    page.UIGridLayout.SortOrder = constants.SortOrder
    page.Parent = menu.Body

    local equippedSlots: Frame = templates.EquippedSlots:Clone()
    equippedSlots.Name = categoryName
    equippedSlots.Visible = false
    equippedSlots.Parent = screen.Equipped

    local tab: ImageButton = templates.Tab:Clone()
    tab.Name = categoryName
    tab.Icon.Image = assert(constants.TabIcon, string.format("%s character editor tab icon is nil: %s", categoryName, categoryName))
    tab.LayoutOrder = constants.TabOrder

    local function updateAppearance()
        CharacterUtil.applyAppearance(preview, { [categoryName] = equippedItems })
    end

    local function isItemOwned(itemName: string)
        return constants.Items[itemName].Price == 0 or itemsOwned[itemName]
    end

    local function onItemOwned(itemName: string)
        local itemInfo = constants.Items[itemName]

        local itemButton: Frame = page[itemName]
        -- Owned items appear first on the list
        itemButton.LayoutOrder = if itemInfo.LayoutOrder then -(itemCount - itemInfo.LayoutOrder) else 0
    end

    local function unequipItem(itemName: string, doNotUpdateAppearance: boolean?)
        page[itemName].BackgroundColor3 = Color3.fromRGB(235, 244, 255)
        if multiEquip then
            equippedSlots[itemName]:Destroy()
        end

        table.remove(equippedItems, table.find(equippedItems, itemName))
        if not doNotUpdateAppearance then
            updateAppearance()
        end
    end

    local function equipItem(itemName: string, doNotUpdateAppearance: boolean?)
        if multiEquip then
            if #equippedItems < constants.MaxEquippables then
                local equippedSlot = templates.EquippedSlot:Clone()
                equippedSlot.Name = itemName
                equippedSlot.Icon.Image = constants.Items[itemName].Icon
                equippedSlot.Parent = equippedSlots

                equippedSlot.Unequip.MouseButton1Down:Connect(function()
                    unequipItem(itemName)
                end)
            else
                -- TODO: Replace with a snackbar
                warn("Cannot equip another item, the max is " .. constants.MaxEquippables)
                return
            end
        else
            local currentlyEquipped = equippedItems[1]
            if currentlyEquipped then
                -- Appearance is updated when the new item is equipped, no point in updating it here
                unequipItem(currentlyEquipped, true)
            end
        end

        table.insert(equippedItems, itemName)
        if not doNotUpdateAppearance then
            updateAppearance()
        end

        page[itemName].BackgroundColor3 = Color3.fromRGB(255, 245, 154)
    end

    -- Items
    for itemName, itemConstants in constants.Items do
        local buttonObject = templates.Item:Clone()
        buttonObject.Name = itemName
        buttonObject.BackgroundColor3 = Color3.fromRGB(235, 244, 255)
        buttonObject.Icon.Image = assert(itemConstants.Icon, string.format("%s character item icon is nil: %s", categoryName, itemName))
        buttonObject.Icon.ImageColor3 = itemConstants.Color or Color3.fromRGB(255, 255, 255)

        local button = Button.new(buttonObject)
        button:Mount(page)

        if isItemOwned(itemName) then
            onItemOwned(itemName)
        else
            buttonObject.LayoutOrder = itemConstants.LayoutOrder or itemCount
        end

        button.InternalPress:Connect(function()
            if isItemOwned(itemName) then
                local isEquipped = table.find(equippedItems, itemName)
                if constants.CanUnequip and isEquipped then
                    unequipItem(itemName)
                elseif not isEquipped then
                    equipItem(itemName)
                end
            else
                -- TODO: Prompt purchase
                -- TODO: Prompt purchase
            end
        end)
    end

    -- Load equipped
    for _, item in DataController.get("CharacterAppearance." .. categoryName) do
        equipItem(item, true)
    end

    function category:GetTab(): ImageButton
        return tab
    end

    function category:GetEquipped(): EquippedItems
        return equippedItems
    end

    function category:SetPreview(character: Model?)
        preview = character
    end

    function category:Open()
        tab.Visible = false
        page.Visible = true

        selectedTab.Visible = true
        selectedTab.Icon.Image = tab.Icon.Image
        selectedTab.LayoutOrder = tab.LayoutOrder
        equippedSlots.Visible = true
    end

    function category:Close()
        page.Visible = false
        tab.Visible = true
        equippedSlots.Visible = false
    end

    return category
end

return CharacterEditorCategory
