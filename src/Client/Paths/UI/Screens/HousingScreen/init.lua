local HousingScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local HousingController: typeof(require(Paths.Client.HousingController))
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local StringUtil = require(Paths.Client.Utils.StringUtil)
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))
local PlotChanger: typeof(require(Paths.Client.HousingController.PlotChanger))
local HousingObjects = require(Paths.Shared.HousingObjectData)
local PlayerData = require(Paths.Client.DataController)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)

local DEBOUNCE_TIME = 0.2

local loadedPrompts = false
local Assets: Folder = Paths.Assets
local templates: Folder = Paths.Templates.Housing
local screenGui: ScreenGui = Paths.UI.Housing
local edit: Frame = screenGui.Edit
local settingsUI: Frame = screenGui.Settings
local plotChangerFrame: Frame = screenGui.PlotChanger
local paint: Frame = screenGui.Paint
local changeHouse: Frame = screenGui.ChangeHouse
local enterEdit: TextButton = screenGui.EnterEdit
local uiStateMachine = UIController.getStateMachine()
local selectedPlot: Model

HousingScreen.itemMove = screenGui.ItemMove

--buttons
local plotChangerExit = KeyboardButton.new()
local exitButton = KeyboardButton.new()
local changeHouseExit = KeyboardButton.new()
local settingsExitButton = KeyboardButton.new()
local plotChange = KeyboardButton.new()
local houseChange = KeyboardButton.new()
local setPlotButton = KeyboardButton.new()

--creates an exit button button, can move to buttonutil
function createExitButton(parent, button)
    button:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    button:Mount(parent, true)
    button:SetPressedDebounce(DEBOUNCE_TIME)
    button:SetIcon("rbxassetid://10979113086")
    button:SetCornerRadius(1)
end

--creates a regular button, can move to buttonutil
function createRegularButton(parent, button, text)
    button:SetColor(UIConstants.Colors.Buttons.PenguinBlue, true)
    button:Mount(parent, true)
    button:SetPressedDebounce(DEBOUNCE_TIME)
    button:SetText(text)
    button:SetCornerRadius(0.15)
    button:SetTextColor(UIConstants.Colors.Buttons.DarkPenguinBlue, true)
end

function HousingScreen.Init()
    HousingController = require(Paths.Client.HousingController)

    createExitButton(edit.ExitButton, exitButton)
    createExitButton(settingsUI.ExitButton, settingsExitButton)
    createExitButton(changeHouse.ExitButton, changeHouseExit)
    createExitButton(plotChangerFrame.ExitButton, plotChangerExit)

    createRegularButton(settingsUI.Center.PlotChange, plotChange, "Change Plot")
    createRegularButton(settingsUI.Center.HouseChange, houseChange, "Change House")
    createRegularButton(plotChangerFrame.SetPlot, setPlotButton, "Select")
end

function HousingScreen.Start()
    EditMode = require(Paths.Client.HousingController.EditMode)
    PlotChanger = require(Paths.Client.HousingController.PlotChanger)
end

--runs when the player plot is changed (only changed on server)
function HousingScreen.plotChanged(newPlot: Model)
    HousingScreen.updatePlotUI(newPlot)
end

--updates the current selected plot ui info
function HousingScreen.updatePlotUI(plot: Model)
    if plot:GetAttribute(HousingConstants.PlotOwner) then
        local owner = Players:GetPlayerByUserId(plot:GetAttribute(HousingConstants.PlotOwner))
        plotChangerFrame.Owner.Text = StringUtil.possesiveName(owner.DisplayName) .. " house"
        plotChangerFrame.SetPlot.Visible = false
    else
        plotChangerFrame.Owner.Text = "Empty"
        plotChangerFrame.SetPlot.Visible = true
    end
end

function HousingScreen.openBottomEdit()
    ScreenUtil.inUp(edit)
end

function HousingScreen.closeBottomEdit()
    ScreenUtil.outDown(edit)
end

function HousingScreen.openColorEdit()
    ScreenUtil.inLeft(paint)
end

function HousingScreen.closeColorEdit()
    ScreenUtil.outLeft(paint)
end

local function editButtonStateChanged()
    local isOpen = uiStateMachine:GetState() == UIConstants.States.HousingEdit
    if isOpen then
        return
    end
    uiStateMachine:PopToAndPush(UIConstants.States.HousingEdit)
end

function HousingScreen.houseEntered(hasEditPerms: boolean)
    if hasEditPerms then
        editButtonStateChanged()
    end
end

function HousingScreen.houseExited()
    uiStateMachine:Pop()

    if uiStateMachine:HasState(UIConstants.States.HousingEdit) then
        uiStateMachine:Remove(UIConstants.States.HousingEdit)
    end

    HousingScreen.enableHousePrompts()
end

--called when player enters Neighborhood zone
function HousingScreen.enableHousePrompts()
    local state = uiStateMachine:GetState()
    if --don't enable house prompts if UI is open that is derived from the prompts
        state == UIConstants.States.PlotSetting
        or state == UIConstants.States.HouseSelectionUI
        or state == UIConstants.States.PlotChanger
    then
        return
    end
    local plots = workspace.Rooms.Neighborhood:WaitForChild("HousingPlots"):GetChildren()
    local promptsDone = 0
    for _, plot in plots do
        task.spawn(function() --use this to handle zone loading streamingenabled
            local Prompt = plot:WaitForChild("Mailbox"):WaitForChild("Prompt")
            Prompt.Enabled = true
            if not loadedPrompts then
                Prompt.Triggered:Connect(function()
                    selectedPlot = plot
                    uiStateMachine:PopToAndPush(UIConstants.States.PlotSetting)
                end)
                promptsDone += 1
            end
        end)
    end
    if not loadedPrompts then
        task.spawn(function()
            repeat
                task.wait()
            until promptsDone == #plots
            loadedPrompts = true
        end)
    end
end

function HousingScreen.disableHousePrompts()
    local plots = workspace.Rooms.Neighborhood:WaitForChild("HousingPlots"):GetChildren()
    for _, plot in plots do
        task.spawn(function()
            local Prompt = plot:WaitForChild("Mailbox"):WaitForChild("Prompt")
            Prompt.Enabled = false
        end)
    end
end

function HousingScreen.itemSelected(item: Model)
    local height = item:GetExtentsSize().Y
    HousingScreen.itemMove.StudsOffset = Vector3.new(0, (height / 2 * -1), 0)
    HousingScreen.itemMove.Adornee = item.PrimaryPart
    HousingScreen.itemMove.Enabled = true
end

function HousingScreen.itemDeselected()
    HousingScreen.itemMove.Adornee = nil
    HousingScreen.itemMove.Enabled = false
end

-- Register UIStates
do
    function HousingScreen.openEditButton()
        enterEdit.Visible = true
    end

    function HousingScreen.exitEditButton()
        enterEdit.Visible = false
    end
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HousingEdit, HousingScreen.openEditButton, HousingScreen.exitEditButton)

    function HousingScreen.enterEdit()
        HousingController.isEditing = true
        enterEdit.Text = "Exit Edit"
        HousingScreen.openBottomEdit()
    end

    function HousingScreen.exitEdit()
        HousingController.isEditing = false
        enterEdit.Text = "Edit"
        EditMode.reset()
        HousingScreen.closeBottomEdit()
    end
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.EditingHouse, HousingScreen.enterEdit, HousingScreen.exitEdit)

    function HousingScreen.openSettings()
        ScreenUtil.sizeOut(settingsUI)
        HousingScreen.disableHousePrompts()
    end

    function HousingScreen.closeSettings()
        ScreenUtil.sizeIn(settingsUI)
        HousingScreen.enableHousePrompts()
    end
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.PlotSetting, HousingScreen.openSettings, HousingScreen.closeSettings)

    function HousingScreen.openHouseChange()
        ScreenUtil.sizeOut(changeHouse)
    end

    function HousingScreen.closeHouseChange()
        ScreenUtil.sizeIn(changeHouse)
    end
    uiStateMachine:RegisterStateCallbacks(
        UIConstants.States.HouseSelectionUI,
        HousingScreen.openHouseChange,
        HousingScreen.closeHouseChange
    )

    function HousingScreen.openPlotChanger()
        PlotChanger.enterPlot(selectedPlot)
        ScreenUtil.sizeOut(plotChangerFrame)
    end

    function HousingScreen.closePlotChanger()
        ScreenUtil.sizeIn(plotChangerFrame)
        PlotChanger.resetCamera()
    end
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.PlotChanger, HousingScreen.openPlotChanger, HousingScreen.closePlotChanger)
end

-- Manipulate UIStates
do
    --open buttons
    enterEdit.MouseButton1Down:Connect(function()
        uiStateMachine:PopToAndPush(UIConstants.States.EditingHouse)
    end)
    houseChange.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.HouseSelectionUI)
    end)
    plotChange.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.PlotChanger)
    end)

    --exit buttons
    exitButton.Pressed:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.EditingHouse)
    end)
    settingsExitButton.Pressed:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.PlotSetting)
    end)
    changeHouseExit.Pressed:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.HouseSelectionUI)
    end)
    plotChangerExit.Pressed:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.PlotChanger)
    end)

    --action buttons
    plotChangerFrame.Left.MouseButton1Down:Connect(function()
        PlotChanger.previousPlot()
    end)

    plotChangerFrame.Right.MouseButton1Down:Connect(function()
        PlotChanger.nextPlot()
    end)
    setPlotButton.Pressed:Connect(function()
        local plot = PlotChanger:GetCurrentPlot()
        if plot and plot:GetAttribute(HousingConstants.PlotOwner) == nil then
            Remotes.fireServer("ChangePlot", plot)
        end
    end)

    local function getPaintColorUI(color: Color3): TextButton | nil
        for _, button in paint.Center.Colors:GetChildren() do
            if button:FindFirstChild("Button") and button.Button.ImageLabel.ImageColor3 == color then
                return button
            end
        end
        return nil
    end

    local selectionTemplate = templates.PaintSelected:Clone()

    function HousingScreen.setDefaultColor(color: Color3)
        paint.Center.Colors.Default.Button.ImageLabel.ImageColor3 = color
    end

    function HousingScreen.changePaintSelected(color: Color3)
        local ui = getPaintColorUI(color)

        if ui then
            selectionTemplate.Parent = ui
        end
    end

    for _, button in paint.Center.Colors:GetChildren() do
        if button:FindFirstChild("Button") then
            button.Button.MouseButton1Down:Connect(function()
                HousingScreen.changePaintSelected(button.Button.ImageLabel.ImageColor3)
                EditMode.itemColorChanged(button.Button.ImageLabel.ImageColor3)
            end)
        end
    end

    --make viewport util?
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

    local objectTemplate = templates.ObjectTemplate
    local ownedItems = PlayerData.get("Igloo.OwnedItems")

    for name, data in HousingObjects do
        local template = objectTemplate:Clone()
        local object = Assets.Housing[data.type]:FindFirstChild(name)

        addModelToViewport(object, template.ViewportFrame)
        template.Name = name
        if ownedItems[name] then
            template.Amount.Text = ownedItems[name]
            template.Amount.Visible = true
        end
        template.Button.MouseButton1Down:Connect(function()
            local amount = PlayerData.get("Igloo.OwnedItems." .. name)
            if amount >= 1 then
                EditMode.newObjectSelected(object:Clone())
                --else
                --todo: prompt purchase
            end
        end)
        template.Parent = edit.Center[data.type]
    end

    Remotes.bindEvents({
        UpdateHouseUI = function(name: string, amount: number, type: string)
            edit.Center[type]:FindFirstChild(name).Amount.Text = amount
        end,
    })

    local OldSelection = nil
    local objectSelectionTemplate = templates.EditSelected:Clone()
    local function SetEditObjectsSelected(name: string)
        if OldSelection then
            if OldSelection[1].Name == name then
                return
            end
            OldSelection[1].AutoButtonColor = true
            OldSelection[1].BackgroundColor3 = Color3.fromRGB(50, 97, 161)
            OldSelection[1].ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
            OldSelection[2].Visible = false
        end
        local button = edit.Buttons[name]
        edit.Center[name].Visible = true
        button.AutoButtonColor = false
        button.BackgroundColor3 = Color3.fromRGB(185, 218, 253)
        button.ImageLabel.ImageColor3 = Color3.fromRGB(50, 97, 161)
        objectSelectionTemplate.Parent = button
        OldSelection = { button, edit.Center[name] }
    end

    SetEditObjectsSelected("Furniture")

    for _, button in pairs(edit.Buttons:GetChildren()) do
        if button:IsA("TextButton") then
            button.MouseButton1Down:Connect(function()
                SetEditObjectsSelected(button.Name)
            end)
        end
    end

    local houses = Assets.Housing.Plot:GetChildren()

    for _, house in houses do
        local model = house:Clone()
        local template = templates.HouseTemplate:Clone()

        template.Name = house.Name
        template.HouseName.Text = house.Name
        addModelToViewport(model, template.ViewportFrame)

        template.Button.MouseButton1Down:Connect(function()
            Remotes.fireServer("ChangePlotModel", house.Name)
        end)

        template.Parent = changeHouse.Center.Houses
    end
end

-- Setup UI
do
    -- Show
    screenGui.Enabled = true
end

return HousingScreen
