local BodyTypeCategory = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CategoryConstants = require(Paths.Shared.Constants.CharacterItems.BodyTypeConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local CharacterEditorCategory = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorCategory)
local DataController = require(Paths.Client.DataController)

local CATEGORY_NAME = "BodyType"

-------------------------------------------------------------------------------
-- Private Members
-------------------------------------------------------------------------------
local screen: ScreenGui = Paths.UI.CharacterEditor
local page = screen.BodyTypes

local preview: Model?
local equippedItem: string

-------------------------------------------------------------------------------
-- Private Methods
-------------------------------------------------------------------------------
local function equipItem(itemName: string, doNotUpdateAppearance: true?)
    -- RETURN: Item is already equipped
    if equippedItem == itemName then
        return
    end

    if equippedItem then
        page[equippedItem].BackgroundColor3 = Color3.fromRGB(235, 244, 255)
    end

    equippedItem = itemName
    page[equippedItem].BackgroundColor3 = Color3.fromRGB(255, 245, 154)

    if not doNotUpdateAppearance then
        CharacterUtil.applyAppearance(preview, { [CATEGORY_NAME] = { equippedItem } })
    end
end

-------------------------------------------------------------------------------
-- Public Methods
-------------------------------------------------------------------------------
function BodyTypeCategory:GetEquipped(): CharacterEditorCategory.EquippedItems?
    return { equippedItem }
end

function BodyTypeCategory:SetPreview(character: Model?)
    preview = character
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------
for itemName, itemConstants in pairs(CategoryConstants.Items) do
    local button = CharacterEditorCategory.createItemButton(itemName, itemConstants, CATEGORY_NAME)
    button:GetButtonObject().LayoutOrder = itemConstants.LayoutOrder
    button:Mount(page)

    button.InternalPress:Connect(function()
        equipItem(itemName)
    end)
end

equipItem(DataController.get("CharacterAppearance." .. CATEGORY_NAME)["1"], true)

return BodyTypeCategory
