local CharacterEditorCategory = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local EditorConstants = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorConstants)
local DataController = require(Paths.Client.DataController)
export type AppearanceChange = { [string]: string }

local templates: Folder = Paths.Templates.CharacterEditor
local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Appearance

function CharacterEditorCategory.new(categoryName: string)
    local category = {}

    -- ERROR: Bad categoryName
    local categoryConstants = EditorConstants[categoryName]
    if not categoryConstants then
        error(string.format("Character item category '%s' does not exist", categoryName))
    end

    local page: Frame = templates.Category:Clone()
    page.Name = categoryName
    page.Visible = false
    page.Parent = menu.Items

    local tabButton: ImageButton = templates.Tab:Clone()
    tabButton.Name = categoryName
    tabButton.Icon.Text = categoryName
    tabButton.LayoutOrder = categoryConstants.LayoutOrder or 100
    tabButton.Parent = menu.Tabs

    local itemConstants = CharacterItems[categoryName]
    local canUnequip: boolean = itemConstants.All.None ~= nil
    local itemCount: number = TableUtil.length(itemConstants.All)
    local itemsOwned: { [string]: any } = DataController.get("Inventory." .. itemConstants.Path)
    local equippedItem: string?
    local appearanceChange: AppearanceChange = {}
    local previewCharacter: Model?

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

    local function onAppearanceChanged(itemName: string)
        appearanceChange = { [categoryName] = itemName }
        CharacterUtil.applyAppearance(previewCharacter, appearanceChange)
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
                if canUnequip and itemIsEquipped then
                    equippedItem = nil
                    itemButton.Equipped.Visible = false

                    onAppearanceChanged("None")
                end

                if not itemIsEquipped then
                    onItemEquipped(itemName)
                    onAppearanceChanged(itemName)
                end
            else
                warn("todo prompt purchase")
                -- TODO: Prompt purchase
            end
        end)
    end

    function category:EquipItem(itemName: string)
        onItemEquipped(itemName)
    end

    function category:SetPreviewCharacter(character: Model?)
        previewCharacter = character
    end

    function category:GetChanges(): AppearanceChange
        return appearanceChange
    end

    return category
end

return CharacterEditorCategory
