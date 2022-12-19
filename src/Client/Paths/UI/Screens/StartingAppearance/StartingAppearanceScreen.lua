local StartingAppearanceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local UIActions = require(Paths.Client.UI.UIActions)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local CharacterPreview = require(Paths.Client.Character.CharacterPreview)

local CHARACTER_PREVIEW_CONFIG = {
    SubjectScale = 14,
}
local COLOR_TAB_NAME = "Color"

local screenGui: ScreenGui = Paths.UI.StartingAppearance
local container: Frame = screenGui.Container
local leftArrowImageButton: ImageButton = container.Character.Left.Button
local rightArrowImageButton: ImageButton = container.Character.Right.Button
local confirmButtonFrame: Frame = container.ConfirmButton

local leftArrow: AnimatedButton.AnimatedButton
local rightArrow: AnimatedButton.AnimatedButton
local confirmButton: KeyboardButton.KeyboardButton
local character: Model
local colorPanel = SelectionPanel.new()

local bootMaid = Maid.new()
local currentColorIndex = 1
local currentOutfitIndex = 1
local hasMadeChange = false

local function updateAppearance()
    local appearance = TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(currentColorIndex, currentOutfitIndex)
    CharacterItemUtil.applyAppearance(character, appearance, true)
end

local function updateOutfitIndex(indexAdd: number)
    currentOutfitIndex = MathUtil.wrapAround(currentOutfitIndex + indexAdd, #TutorialConstants.StartingAppearance.Outfits)
    hasMadeChange = true

    updateAppearance()
end

local function getColorWidgetNameFromColorIndex(colorIndex: number)
    return tostring(colorIndex)
end

function StartingAppearanceScreen.Init()
    -- Buttons
    do
        leftArrow = AnimatedButton.new(leftArrowImageButton)
        leftArrow:SetHoverAnimation(nil)
        leftArrow:SetPressAnimation(nil)
        leftArrow.Pressed:Connect(function()
            updateOutfitIndex(-1)
        end)

        rightArrow = AnimatedButton.new(rightArrowImageButton)
        rightArrow:SetHoverAnimation(nil)
        rightArrow:SetPressAnimation(nil)
        rightArrow.Pressed:Connect(function()
            updateOutfitIndex(1)
        end)

        local function confirmChanges()
            TutorialController.setStartingAppearance(currentColorIndex, currentOutfitIndex)
            UIController.getStateMachine():PopTo(UIConstants.States.HUD)
        end

        confirmButton = KeyboardButton.new()
        confirmButton:SetColor(UIConstants.Colors.Buttons.NextGreen)
        confirmButton:SetText("I am ready!")
        confirmButton:Mount(confirmButtonFrame, true)
        confirmButton.Pressed:Connect(function()
            -- PROMPT: User has gone to confirm without trying any changes! Bit of UX here
            if not hasMadeChange then
                UIActions.prompt(
                    "Are you sure?",
                    "You didn't try any new colors or outfits! Are you sure you want to confirm your penguin's look?",
                    function(parent, maid)
                        local imageLabel = Instance.new("ImageLabel")
                        imageLabel.Size = UDim2.fromScale(1, 1)
                        imageLabel.BackgroundTransparency = 1
                        imageLabel.Image = Images.PizzaFiasco.Doodle3
                        imageLabel.ScaleType = Enum.ScaleType.Fit
                        imageLabel.Parent = parent

                        maid:GiveTask(imageLabel)
                    end,
                    {
                        Text = "Yes, confirm!",
                        Color = UIConstants.Colors.Buttons.NextGreen,
                        Callback = confirmChanges,
                    },
                    {
                        Text = "No, wait..",
                        Color = UIConstants.Colors.Buttons.WaitOrange,
                    }
                )
                return
            end

            confirmChanges()
        end)
    end

    -- Color Panel Setup
    do
        colorPanel:Mount(screenGui)
        colorPanel:SetAlignment("Left")
        colorPanel:SetSize(1)
        colorPanel:SetCloseButtonVisibility(false)

        colorPanel:AddTab(COLOR_TAB_NAME, Images.Icons.PaintBucket)
        for colorIndex, colorName in pairs(TutorialConstants.StartingAppearance.Colors) do
            local product = ProductUtil.getCharacterItemProduct("FurColor", colorName)
            colorPanel:AddWidgetFromProduct(COLOR_TAB_NAME, getColorWidgetNameFromColorIndex(colorIndex), false, product, nil, function()
                -- RETURN: Already selected!
                if currentColorIndex == colorIndex then
                    return
                end

                -- Toggle selected widgets
                colorPanel:SetWidgetSelected(COLOR_TAB_NAME, getColorWidgetNameFromColorIndex(currentColorIndex), false)
                colorPanel:SetWidgetSelected(COLOR_TAB_NAME, getColorWidgetNameFromColorIndex(colorIndex), true)

                -- Update variables
                currentColorIndex = colorIndex
                hasMadeChange = true

                updateAppearance()
            end)
        end

        ScreenUtil.outLeft(colorPanel:GetContainer())
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.StartingAppearance, {
        Boot = StartingAppearanceScreen.boot,
        Shutdown = StartingAppearanceScreen.shutdown,
        Maximize = StartingAppearanceScreen.maximize,
        Minimize = StartingAppearanceScreen.minimize,
    })
end

function StartingAppearanceScreen.boot()
    -- Init
    currentColorIndex = math.random(1, #TutorialConstants.StartingAppearance.Colors) -- Random Color
    currentOutfitIndex = 1
    hasMadeChange = false

    -- Select initial color widget
    colorPanel:SetWidgetSelected(COLOR_TAB_NAME, getColorWidgetNameFromColorIndex(currentColorIndex), true)

    -- Character Preview
    local previewCharacter, previewMaid = CharacterPreview.preview(CHARACTER_PREVIEW_CONFIG)
    character = previewCharacter
    bootMaid:GiveTask(previewMaid)

    updateAppearance()
end

function StartingAppearanceScreen.shutdown()
    bootMaid:Cleanup()
end

function StartingAppearanceScreen.minimize()
    ScreenUtil.outUp(container)
    ScreenUtil.outLeft(colorPanel:GetContainer())
end

function StartingAppearanceScreen.maximize()
    ScreenUtil.inRight(colorPanel:GetContainer())
    ScreenUtil.inDown(container)
    screenGui.Enabled = true
end

return StartingAppearanceScreen
