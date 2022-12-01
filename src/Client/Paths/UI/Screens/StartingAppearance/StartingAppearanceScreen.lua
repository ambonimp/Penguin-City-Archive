local StartingAppearanceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local TabbedWindow = require(Paths.Client.UI.Elements.TabbedWindow)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)
local InventoryProductWindow = require(Paths.Client.UI.Screens.Inventory.InventoryProductWindow)
local InventoryPetsWindow = require(Paths.Client.UI.Screens.Inventory.InventoryPetsWindow)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local VehicleController = require(Paths.Client.VehicleController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetController = require(Paths.Client.Pets.PetController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local TutorialController = require(Paths.Client.TutorialController)
local UIActions = require(Paths.Client.UI.UIActions)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)

local screenGui: ScreenGui = Paths.UI.StartingAppearance
local container: Frame = screenGui.Container
local leftArrowImageButton: ImageButton = container.Character.Left.Button
local rightArrowImageButton: ImageButton = container.Character.Right.Button
local characterViewportFrame: ViewportFrame = container.Character.ViewportFrame
local confirmButtonFrame: Frame = container.ConfirmButton

local leftArrow: AnimatedButton.AnimatedButton
local rightArrow: AnimatedButton.AnimatedButton
local confirmButton: KeyboardButton.KeyboardButton
local colorPanel = SelectionPanel.new()

local currentColorIndex = 1
local currentOutfitIndex = 1
local hasMadeChange = false

local function updateAppearance()
    local appearance = TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(currentColorIndex, currentOutfitIndex)
    print("todo apply appearance", appearance)
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
            UIController.getStateMachine():Remove(UIConstants.States.StartingAppearance)
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
            colorPanel:AddWidgetFromProduct("Color", colorName, product, nil, function()
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

    updateAppearance()
end

function StartingAppearanceScreen.shutdown()
    --todo
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
