local HousingScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Button = require(Paths.Client.UI.Elements.Button)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))
local PlayerData = require(Paths.Client.DataController)
local HouseObjects = require(Paths.Shared.Constants.HouseObjects)

local DEFAULT_EDIT_CATEGORY = "Furniture"

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local loadedPrompts = false

local uiStateMachine = UIController.getStateMachine()

local templates: Folder = Paths.Templates.Housing
local assets: Folder = Paths.Assets.Housing

local screenGui: ScreenGui = Paths.UI.Housing
local paintFrame: Frame = screenGui.Paint
local editFrame: Frame = screenGui.Edit
local editCategoryTabs: Frame = editFrame.Tabs
local editCategoryPages: Frame = editFrame.Center

local editToggleContainer: Frame = screenGui.EditToggle
local editToggleButton: typeof(KeyboardButton.new())

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
HousingScreen.ItemMove = screenGui.ItemMove

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function HousingScreen.Start()
    EditMode = require(Paths.Client.HousingController.EditMode)
end

function HousingScreen.openColorEdit()
    ScreenUtil.inLeft(paintFrame)
end

function HousingScreen.closeColorEdit()
    ScreenUtil.outLeft(paintFrame)
end

function HousingScreen.itemSelected(item: Model)
    local height = item:GetExtentsSize().Y
    HousingScreen.ItemMove.StudsOffset = Vector3.new(0, (height / 2 * -1), 0)
    HousingScreen.ItemMove.Adornee = item.PrimaryPart
    HousingScreen.ItemMove.Enabled = true
end

function HousingScreen.itemDeselected()
    HousingScreen.ItemMove.Adornee = nil
    HousingScreen.ItemMove.Enabled = false
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Register UIStates
do
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.House, function(data)
        if data.CanEdit then
            editToggleContainer.Visible = true
            editToggleButton:SetText("Edit")
        end
    end, function()
        if not uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            editToggleContainer.Visible = false
        end
    end)

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HouseEditor, function()
        editToggleButton:SetText("Exit Edit")
        editToggleContainer.Visible = true

        ScreenUtil.inUp(editFrame)
    end, function()
        -- Actual closing and not just opening FurniturePlacement
        if
            not (
                uiStateMachine:HasState(UIConstants.States.HouseEditor)
                and uiStateMachine:GetState() == UIConstants.States.FurniturePlacement
            )
        then
            EditMode.reset()
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
            uiStateMachine:Push(UIConstants.States.HouseEditor)
        end
    end)
    editToggleButton:Mount(editToggleContainer, true)

    local exitButton = ExitButton.new()
    exitButton:Mount(editFrame.ExitButton, true)
    exitButton.Pressed:Connect(close)
end

-- Paint
do
    local function getPaintColorUI(color: Color3): TextButton | nil
        for _, button in paintFrame.Center.Colors:GetChildren() do
            if button:FindFirstChild("Button") and button.Button.ImageLabel.ImageColor3 == color then
                return button
            end
        end
        return nil
    end

    local selectionTemplate = templates.PaintSelected:Clone()

    function HousingScreen.setDefaultColor(color: Color3)
        paintFrame.Center.Colors.Default.Button.ImageLabel.ImageColor3 = color
    end

    function HousingScreen.changePaintSelected(color: Color3)
        local ui = getPaintColorUI(color)

        if ui then
            selectionTemplate.Parent = ui
        end
    end

    for _, button in paintFrame.Center.Colors:GetChildren() do
        if button:FindFirstChild("Button") then
            button.Button.MouseButton1Down:Connect(function()
                HousingScreen.changePaintSelected(button.Button.ImageLabel.ImageColor3)
                EditMode.itemColorChanged(button.Button.ImageLabel.ImageColor3)
            end)
        end
    end
end

-- Categories
do
    local currentCategory: string?
    local selectedBackground: Frame = editCategoryTabs.SelectedTab

    local function addModelToViewport(model: Model, viewport: ViewportFrame)
        local _, size
        _, size = model:GetBoundingBox()

        local camera = viewport.CurrentCamera or Instance.new("Camera")
        camera.Parent = viewport
        viewport.CurrentCamera = camera
        local fitDepth = CameraUtil.getFitDeph(camera.ViewportSize, camera.FieldOfView, size) -- +offset
        local clone = model:Clone()
        clone.Parent = viewport

        camera.CFrame = CFrame.new(clone:GetPivot() * CFrame.new(Vector3.new(0, 0, -fitDepth)).Position, clone:GetPivot().Position)
    end

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
        for objectName, objectInfo in pairs(categoryConstants.Objects) do
            local objectButtonObject: ImageButton = templates.Object:Clone()
            objectButtonObject.Name = objectName

            local objectButton = Button.new(objectButtonObject)
            objectButton.Pressed:Connect(function()
                --[[
                    TODO:
                    -- Prompt purchase if objectInfo.Price ~= 0
                    -- Different handles depending on the objects
                        -- if categoryName == ObjectPlacement then open edit mode
                ]]
            end)
            objectButton:Mount(page)
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
