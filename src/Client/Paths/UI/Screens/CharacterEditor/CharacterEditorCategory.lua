local CharacterEditorCategory = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local DataController = require(Paths.Client.DataController)
local Signal = require(Paths.Shared.Signal)
local Button = require(Paths.Client.UI.Elements.Button)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductController = require(Paths.Client.ProductController)

export type EquippedItems = { string }
export type ItemInfo = { Name: string, Icon: string, Color: Color3? }

local BUTTON_SCALE_UP_ANIMATION = AnimatedButton.Animations.Squish(UDim2.fromScale(1.15, 1.15))
local BUTTON_SCALE_DOWN_ANIMATION = AnimatedButton.Animations.Squish(UDim2.fromScale(0.9, 0.9))

local LOCKED_ITEM = {
    BackgroundTransparency = 0.7,
    ImageTransparency = 0.3,
}
local OWNED_ITEM = {
    BackgroundTransparency = 0,
    ImageTransparency = 0,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local templates: Folder = Paths.Templates.CharacterEditor
local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Edit
local tabs: Frame = menu.Tabs
local selectedTab: Frame = tabs.SelectedTab

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CharacterEditorCategory.createItemButton(
    itemName: string,
    itemInfo: ItemInfo,
    categoryName
): typeof(Button.new(Instance.new("ImageButton")))
    local buttonObject = templates.Item:Clone()
    buttonObject.Name = itemName
    buttonObject.BackgroundColor3 = Color3.fromRGB(235, 244, 255)
    buttonObject.BackgroundTransparency = LOCKED_ITEM.BackgroundTransparency
    buttonObject.Icon.Image = assert(itemInfo.Icon, string.format("%s character item icon is nil: %s", categoryName, itemName))
    buttonObject.Icon.ImageColor3 = itemInfo.Color or Color3.fromRGB(255, 255, 255)
    buttonObject.Icon.ImageTransparency = LOCKED_ITEM.BackgroundTransparency

    return Button.new(buttonObject)
end

function CharacterEditorCategory.new(categoryName: string)
    local category = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    local preview: Model?
    local equippedItems: EquippedItems?

    local constants = CharacterItems[categoryName]
    local itemCount: number = TableUtil.length(constants.Items)
    local multiEquip: boolean = constants.MaxEquippables > 1
    local canEquip: boolean = constants.MaxEquippables ~= 0

    local page: Frame = templates.CategoryPage:Clone()
    page.Name = categoryName
    page.Visible = false
    page.UIGridLayout.SortOrder = constants.SortOrder
    page.Parent = menu.Body

    local equippedSlots: Frame?
    if multiEquip then
        equippedSlots = templates.EquippedSlots:Clone()
        equippedSlots.Name = categoryName
        equippedSlots.Visible = false
        equippedSlots.Parent = screen.Equipped
    end

    local tab: ImageButton = templates.Tab:Clone()
    tab.Name = categoryName
    tab.Icon.Image = assert(constants.TabIcon, string.format("%s character editor tab icon is nil: %s", categoryName, categoryName))
    tab.LayoutOrder = constants.TabOrder

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------
    category.Changed = Signal.new()

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------
    local function updateAppearance(psuedoEquippedItems: EquippedItems?)
        category.Changed:Fire(CharacterUtil.applyAppearance(preview, { [categoryName] = psuedoEquippedItems or equippedItems }))
    end

    local function isItemOwned(itemName: string)
        local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
        return ProductUtil.isFree(product) or ProductController.hasProduct(product)
    end

    local function onItemOwned(itemName: string)
        local itemInfo = constants.Items[itemName]

        local itemButton: Frame = page[itemName]
        itemButton.LayoutOrder = itemInfo.LayoutOrder and -(itemCount - itemInfo.LayoutOrder) or 0
        itemButton.BackgroundTransparency = OWNED_ITEM.BackgroundTransparency
        itemButton.Icon.ImageTransparency = OWNED_ITEM.ImageTransparency
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

    local function equipItem(itemName: string, doNotUpdateAppearance: true?)
        -- RETURN: Item is already equipped
        if table.find(equippedItems, itemName) then
            return
        end

        if multiEquip then
            if #equippedItems < constants.MaxEquippables then
                local slot: ImageButton = templates.EquippedSlot:Clone()
                slot.Name = itemName
                slot.Icon.Image = constants.Items[itemName].Icon

                local slotButton = AnimatedButton.new(slot)
                slotButton.InternalRelease:Connect(function()
                    task.wait(0.1) -- Just makes it more satifying
                    unequipItem(itemName)
                end)
                slotButton.InternalEnter:Connect(function()
                    slot.Unequip.Visible = true
                end)
                slotButton.InternalLeave:Connect(function()
                    slot.Unequip.Visible = false
                end)

                slotButton:SetPressAnimation(BUTTON_SCALE_DOWN_ANIMATION)
                slotButton:SetHoverAnimation(BUTTON_SCALE_UP_ANIMATION)
                slotButton:MountToUnconstrained(equippedSlots)
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

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------
    function category:GetTab(): ImageButton
        return tab
    end

    function category:Equip(equipping: EquippedItems, doNotUpdateAppearance: true?)
        for _, itemName in pairs(equipping) do
            equipItem(itemName, doNotUpdateAppearance)
        end
    end

    function category:GetEquipped(): EquippedItems?
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

        if multiEquip then
            equippedSlots.Visible = true
        end
    end

    function category:Close()
        page.Visible = false
        tab.Visible = true
        if multiEquip then
            equippedSlots.Visible = false
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Create UI
    for itemName, itemConstants in pairs(constants.Items) do
        local button = CharacterEditorCategory.createItemButton(itemName, itemConstants, categoryName)
        button:Mount(page)

        if isItemOwned(itemName) then
            onItemOwned(itemName)
        else
            button:GetButtonObject().LayoutOrder = itemConstants.LayoutOrder or itemCount
        end

        local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
        button.InternalPress:Connect(function()
            if isItemOwned(itemName) then
                if not canEquip then
                    updateAppearance({ itemName })
                    return
                end

                local isEquipped = table.find(equippedItems, itemName)
                if constants.CanUnequip and isEquipped then
                    unequipItem(itemName)
                elseif not isEquipped then
                    equipItem(itemName)
                end
            else
                ProductController.prompt(product)
            end
        end)
    end

    -- Listen for added products
    ProductController.ProductAdded:Connect(function(addedProduct, _amount)
        if ProductUtil.isCharacterItemProduct(addedProduct) then
            local data = ProductUtil.getCharacterItemProductData(addedProduct)
            if data.CategoryName == categoryName then
                onItemOwned(data.ItemKey)
            end
        end
    end)

    if canEquip then
        equippedItems = {}
        category:Equip(DataController.get("CharacterAppearance." .. categoryName) :: EquippedItems, true)
    end

    return category
end

return CharacterEditorCategory
