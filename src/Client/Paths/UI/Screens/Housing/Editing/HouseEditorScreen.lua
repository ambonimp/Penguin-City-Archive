local HousingScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Button = require(Paths.Client.UI.Elements.Button)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local HouseObjects = require(Paths.Shared.Constants.HouseObjects)
local FurniturePage = require(Paths.Client.UI.Screens.Housing.Editing.FurniturePage)

local DEFAULT_EDIT_CATEGORY = "Furniture"

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local uiStateMachine = UIController.getStateMachine()

local templates: Folder = Paths.Templates.Housing
local assets: Folder = Paths.Assets.Housing

local screenGui: ScreenGui = Paths.UI.Housing
local editFrame: Frame = screenGui.Edit
local editCategoryTabs: Frame = editFrame.Tabs
local editCategoryPages: Frame = editFrame.Center

local editToggleContainer: Frame = screenGui.EditToggle
local editToggleButton: typeof(KeyboardButton.new())

local interiorPlot: Model?

local canEdit: boolean?
-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function defaultCategoryPage(categoryName: string, models: Folder, pressCallback: () -> ()?)
    local page: ScrollingFrame = editCategoryPages[categoryName]

    for objectName, objectInfo in pairs(HouseObjects[categoryName].Objects) do
        local objectButtonObject: ImageButton = templates.Object:Clone()
        objectButtonObject.Name = objectName

        local price = objectInfo.Price
        objectButtonObject.Price.Text = "$" .. price

        CameraUtil.lookAtModelInViewport(objectButtonObject.ViewportFrame, models[objectName]:Clone())

        local objectButton = Button.new(objectButtonObject)
        objectButton.Pressed:Connect(function()
            if pressCallback then
                pressCallback()
            end
        end)
        objectButton:Mount(page)
    end
end

-----------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Register UIStates
do
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.House, function(data)
        canEdit = data.CanEdit or canEdit
        if canEdit then
            editToggleButton:SetText("Edit", true)
            editToggleContainer.Visible = true

            interiorPlot = data.InteriorPlot or interiorPlot
        end
    end, function()
        if not uiStateMachine:HasState(UIConstants.States.House) then
            interiorPlot = nil
            canEdit = nil
        elseif uiStateMachine:GetState() ~= UIConstants.States.HouseEditor then
            editToggleContainer.Visible = false
        end
    end)

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HouseEditor, function()
        editToggleButton:SetText("Exit Edit")
        editToggleContainer.Visible = true

        ScreenUtil.inUp(editFrame)
    end, function()
        if uiStateMachine:GetState() ~= UIConstants.States.House then
            editToggleContainer.Visible = false
        end

        ScreenUtil.outDown(editFrame)
    end)
end

-- Manipulate UIStates
do
    local function close()
        uiStateMachine:PopTo(UIConstants.States.House, { CanEdit = true })
    end

    editToggleButton = WideButton.green("Edit")
    editToggleButton.Pressed:Connect(function()
        if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            close()
        else
            uiStateMachine:Push(UIConstants.States.HouseEditor, {
                InteriorPlot = interiorPlot,
            })
        end
    end)
    editToggleButton:Mount(editToggleContainer, true)

    local exitButton = ExitButton.new()
    exitButton:Mount(editFrame.ExitButton, true)
    exitButton.Pressed:Connect(close)
end

-- Categories
do
    local currentCategory: string?
    local selectedBackground: Frame = editCategoryTabs.SelectedTab

    local function openCategory(newCategory: string)
        -- RETURN: Category is already active
        if newCategory == currentCategory then
            return
        end

        if currentCategory then
            editCategoryTabs[currentCategory].Visible = true
            editCategoryPages[currentCategory].Visible = false
        end

        currentCategory = newCategory

        local tabButton = editCategoryTabs[newCategory]
        tabButton.Visible = false
        selectedBackground.Icon.Image = tabButton.Icon.Image
        selectedBackground.LayoutOrder = tabButton.LayoutOrder

        editCategoryPages[newCategory].Visible = true
    end

    for categoryName, categoryConstants in pairs(HouseObjects) do
        -- Tab
        local tabButtonObject: TextButton = templates.EditCategoryTab:Clone()
        tabButtonObject.Icon.Image = categoryConstants.TabIcon
        tabButtonObject.Name = categoryName
        tabButtonObject.LayoutOrder = categoryConstants.TabOrder

        local tabButton = Button.new(tabButtonObject)
        tabButton.Pressed:Connect(function()
            openCategory(categoryName)
        end)
        tabButton:Mount(editCategoryTabs)

        -- Page
        local page = templates.EditCategoryPage:Clone()
        page.Name = categoryName
        page.Visible = false
        page.Parent = editCategoryPages

        -- Load objects
        if categoryName == "Furniture" then
            FurniturePage.loadItems()
        elseif categoryName == "Blueprint" then
            defaultCategoryPage("Blueprint", assets.Exteriors, function()
                print("Hello World2")
            end)
        end
    end

    openCategory(DEFAULT_EDIT_CATEGORY)
end
-- Setup UI
do
    -- Show
    screenGui.Enabled = true
end

return HousingScreen
