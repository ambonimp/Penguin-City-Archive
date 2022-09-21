local CharacterEditorCategory = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIController = require(Paths.Client.UI.UIController)
local CharacterEditorScreen = require(Paths.Client.UI.Screens.CharacterEditorScreen)
local EditorConstants = require(Paths.Client.UI.Screens.CharacterEditorScreen.CharacterEditorConstants)
local PlayerDataController = require(Paths.Client.PlayerData)

local templates: Folder = ReplicatedStorage.Templates.CharacterEditor
local screen: ScreenGui = UIController.getScreen("CharacterEditor")
local menu: Frame = screen.Appearance

function CharacterEditorCategory.new(categoryName: string)
    local category = {}
    local categoryConstants = EditorConstants[categoryName]

    local page: Frame = templates.Category:Clone()
    page.Name = categoryName
    page.Visible = false
    page.Parent = menu.Items

    local itemConstants = require(Paths.Shared.Constants.CharacterItems[categoryName .. "Constants"])
    local itemCount = TableUtil.length(itemConstants.All)
    local itemsOwned = PlayerDataController.get("Inventory." .. itemConstants.Path)
    local equippedItem: string?

    local function isItemOwned(itemName: string)
        return itemConstants.All[itemName].Price == 0 or itemsOwned[itemName]
    end

    local function onItemOwned(itemName: string)
        local itemInfo = itemConstants.All[itemName]

        local itemButton: ImageButton = page[itemName]
        itemButton.ImageColor3 = Color3.fromRGB(254, 255, 214)
        -- Owned items appear first on the list
        itemButton.LayoutOrder = if itemInfo.LayoutOrder then -(itemCount - itemInfo.LayoutOrder) else 0
    end

    local function onItemEquipped(itemName: string)
        local itemButton: ImageButton
        -- Unequip last item
        if equippedItem then
            itemButton = page[equippedItem]
            itemButton.Equipped.Visible = false
        end

        itemButton = page[itemName]
        itemButton.Equipped.Visible = true

        equippedItem = itemName
    end

    function category:EquipItem(itemName: string)
        onItemEquipped(itemName)
    end

    -- Loading
    -- Tabs
    local tabButton: ImageButton = templates.Tab:Clone()
    tabButton.Icon.Text = categoryName
    tabButton.LayoutOrder = categoryConstants.LayoutOrder or 100
    tabButton.Parent = menu.Tabs
    tabButton.MouseButton1Down:Connect(function()
        CharacterEditorScreen.openCategory(categoryName)
    end)

    if categoryConstants.IsDefaultCategory then
        CharacterEditorScreen.openCategory(categoryName)
    end

    -- Items
    for itemName, itemInfo in itemConstants.All do
        local itemButton: ImageButton = templates.ListItem:Clone()
        itemButton.Name = itemName
        itemButton:FindFirstChild("Name").Text = itemName
        itemButton.Parent = page

        if isItemOwned(itemName) then
            onItemOwned(itemName)
        else
            itemButton.LayoutOrder = itemInfo.LayoutOrder or itemCount
        end

        itemButton.MouseButton1Down:Connect(function()
            if isItemOwned(itemName) then
                local itemIsEquipped = itemName == equippedItem
                if categoryConstants.CanUnequip and itemIsEquipped then
                    equippedItem = nil
                    itemButton.Equipped.Visible = false

                    CharacterEditorScreen.saveAppearanceChange(categoryName, "None") --*
                end

                if not itemIsEquipped then
                    onItemEquipped(itemName)
                    CharacterEditorScreen.previewAppearanceChange(categoryName, itemName)
                end
            else
                -- TODO: Prompt purchase
            end
        end)
    end

    return category
end

return CharacterEditorCategory
