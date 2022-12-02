local StartingAppearanceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local TutorialController = require(Paths.Client.TutorialController)
local UIActions = require(Paths.Client.UI.UIActions)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local CharacterPreview = require(Paths.Client.Character.CharacterPreview)

local CHARACTER_PREVIEW_CONFIG = {}

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
    CharacterUtil.applyAppearance(character, appearance, true)
end

local function updateOutfitIndex(indexAdd: number)
    currentOutfitIndex = MathUtil.wrapAround(currentOutfitIndex + indexAdd, #TutorialConstants.StartingAppearance.Outfits)
    hasMadeChange = true

    updateAppearance()
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
                        imageLabel.Image = Images.PizzaMinigame.Doodle3
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

        colorPanel:AddTab("Color", Images.Icons.PaintBucket)
        for colorIndex, colorName in pairs(TutorialConstants.StartingAppearance.Colors) do
            local product = ProductUtil.getCharacterItemProduct("FurColor", colorName)
            colorPanel:AddWidgetFromProduct("Color", colorName, false, product, nil, function()
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
    currentColorIndex = 1
    currentOutfitIndex = 1
    hasMadeChange = false

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
