local FurnitureSelectionScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local InputController = require(Paths.Client.Input.InputController)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local Widget = require(Paths.Client.UI.Elements.Widget)
local Images = require(Paths.Shared.Images.Images)
local FurnitureConstants = require(Paths.Shared.Constants.HouseObjects.FurnitureConstants)
local ProductController = require(Paths.Client.ProductController)
local HousingController = require(Paths.Client.HousingController)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local PlacementScreen = require(Paths.Client.UI.Screens.Housing.Editing.PlacementScreen)
-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local furniturePanel = SelectionPanel.new()
local uiStateMachine = UIController.getStateMachine()

local templates: Folder = Paths.Templates.Housing

local screenGui: ScreenGui = Paths.UI.Housing

local editToggleContainer: Frame = screenGui.EditToggle
local editToggleButton: typeof(KeyboardButton.new())

local editingSession = Maid.new()

local player: Player = Players.LocalPlayer
local plot: Model?

--HouseEditor UI state
do
    local function boot(_data)
        screenGui.Enabled = true
        ScreenUtil.inDown(editToggleContainer)
        ScreenUtil.inUp(furniturePanel:GetContainer())
        -- See if we can get plot
        local zoneOwner = ZoneUtil.getHouseInteriorZoneOwner(ZoneController.getCurrentZone())
        local thisPlot = HousingController.getPlotFromOwner(zoneOwner, HousingConstants.InteriorType)
        thisPlot:FindFirstChildOfClass("Model").NoPlace.Transparency = 0.5
        -- RETURN: There is nothing to edit off of
        plot = thisPlot
        if not plot then
            warn("Had issue with getting plot")
            UIController.getStateMachine():Remove(UIConstants.States.HouseEditor)
            return
        end
        editingSession:GiveTask(InputController.CursorDown:Connect(function(gameProcessedEvent)
            -- RETURN: Clicked something unrelated
            if gameProcessedEvent then
                return
            end
            -- RETURN: player is teleporting out of house
            if ZoneController.isTeleporting() then
                return
            end

            -- Selecting an item to edit
            local result = MouseUtil.getMouseTarget({ player.Character }, true)
            local target = result.Instance

            if target and target:IsDescendantOf(plot.Furniture) then
                if string.find(target.Parent.Name, "Color") then
                    target = target.Parent
                end

                local model_ = target.Parent
                if uiStateMachine:GetState() == UIConstants.States.FurniturePlacement then
                    if uiStateMachine:GetData().Object == model_ then
                        return
                    else
                        uiStateMachine:Pop()
                    end
                end

                uiStateMachine:Push(UIConstants.States.FurniturePlacement, {
                    Object = model_,
                    Plot = plot,
                    PlotCFrame = CFrame.new(plot:WaitForChild("Origin").Position),
                    IsNewObject = false,
                })
            end
        end))
    end

    local function shutdown()
        plot:FindFirstChildOfClass("Model").NoPlace.Transparency = 1
        editingSession:Cleanup()
        ScreenUtil.outDown(furniturePanel:GetContainer())
        ScreenUtil.outUp(editToggleContainer)
    end

    local function maximize()
        ScreenUtil.inDown(editToggleContainer)
        ScreenUtil.inUp(furniturePanel:GetContainer())
    end

    local function minimize()
        ScreenUtil.outUp(editToggleContainer)
        ScreenUtil.outDown(furniturePanel:GetContainer())
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.HouseEditor, {
        Boot = boot,
        Shutdown = shutdown,
        Maximize = maximize,
        Minimize = minimize,
    })

    UIUtil.offsetGuiInset(editToggleContainer)
    editToggleButton = WideButton.red("Stop Edit")
    editToggleButton.Pressed:Connect(function()
        if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            uiStateMachine:Remove(UIConstants.States.HouseEditor)
        else
            uiStateMachine:Push(UIConstants.States.HouseEditor, {})
        end
    end)

    editToggleButton:Mount(editToggleContainer, true)
    ScreenUtil.outUp(editToggleContainer)

    --furniture panel
    do
        furniturePanel:Mount(screenGui)

        furniturePanel:SetAlignment("Bottom")
        furniturePanel:SetSize(1)
        furniturePanel.ClosePressed:Connect(function()
            uiStateMachine:Remove(UIConstants.States.HouseEditor)
        end)

        local button: Frame = templates.BackButton:Clone()
        button.Parent = furniturePanel:GetContainer().Background

        local BackButton = KeyboardButton.new()
        local ObjectsFrame: ScrollingFrame = templates.ObjectFrame:Clone()

        BackButton:Mount(button, true)
        BackButton:SetIcon(Images.Icons.LeftArrow)
        BackButton:GetButtonObject().Parent.Visible = false
        BackButton:GetButtonObject().Parent.Size = furniturePanel:GetContainer().Background.Side.ForwardArrow.Size

        furniturePanel:HideForwardArrow()
        ObjectsFrame.Parent = furniturePanel:GetContainer().Background.Back

        local function setCategoryVisible(on: boolean, tag: string?)
            ObjectsFrame.Visible = on
            if tag == "Owned" then
                BackButton:GetButtonObject().Parent.Visible = false
            else
                BackButton:GetButtonObject().Parent.Visible = on
            end
            furniturePanel:GetContainer().Background.Back.ScrollingFrame.Visible = not on
        end

        local function loadNewItems(tag: string, objects: { [string]: FurnitureConstants.Object })
            for _, v in pairs(ObjectsFrame:GetChildren()) do
                if not v:IsA("UIListLayout") then
                    v:Destroy()
                end
            end

            for objectKey, _objectInfo in objects do
                local product = ProductUtil.getHouseObjectProduct("Furniture", objectKey)
                local add = true
                if tag == "Owned" then
                    if not ProductController.hasProduct(product) then
                        add = false
                    end
                end
                if add then
                    local objectWidget = Widget.diverseWidgetFromHouseObject("Furniture", objectKey)
                    objectWidget:GetGuiObject().Parent = ObjectsFrame
                end
            end

            setCategoryVisible(true, tag)
        end

        furniturePanel.TabChanged:Connect(function(_oldTab: string, newTab: string)
            if newTab == "Owned" then
                loadNewItems("Owned", FurnitureConstants.Objects)
            else
                setCategoryVisible(false)
            end
        end)

        furniturePanel:SetScrollingframeAlignment(Enum.HorizontalAlignment.Left)

        local function getObjectCount(objects: { string: FurnitureConstants.Object }): number
            local count = 0
            for _i, _v in objects do
                count += 1
            end
            return count
        end

        local function addWidget(tabName: string, tag: string)
            local objects = FurnitureConstants.GetObjectsFromTag(tag)
            local count = getObjectCount(objects)
            if count == 0 then
                return
            end
            furniturePanel:AddWidgetConstructor(tabName, tag, false, function(parent, maid)
                local widget = Widget.diverseWidget()
                widget:DisableIcon()
                widget:SetText(tag)

                widget.Pressed:Connect(function()
                    loadNewItems(tag, objects)
                end)

                widget:Mount(parent)
                maid:GiveTask(widget)
                return widget
            end)
        end

        furniturePanel:AddTab("All", Images.Icons.Igloo)
        for _, tag in FurnitureConstants.Tags do
            addWidget("All", tag)
        end
        for tabName, info in FurnitureConstants.MainTabs do
            local icon = info.Icon
            local subtabs = info.SubTabs
            furniturePanel:AddTab(tabName, icon)
            for _, tag in subtabs do
                addWidget(tabName, tag)
            end
        end
        furniturePanel:AddTab("Owned", Images.Icons.Furniture)

        BackButton.Pressed:Connect(function()
            setCategoryVisible(false)
        end)

        setCategoryVisible(false)
    end

    ScreenUtil.outDown(furniturePanel:GetContainer())
end

return FurnitureSelectionScreen
