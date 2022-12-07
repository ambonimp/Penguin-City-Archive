local FurnitureEditingPage = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local InputController = require(Paths.Client.Input.InputController)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local Widget = require(Paths.Client.UI.Elements.Widget)
local Images = require(Paths.Shared.Images.Images)
local FurnitureConstants = require(Paths.Shared.Constants.HouseObjects.FurnitureConstants)
local ProductController = require(Paths.Client.ProductController)
local PartUtil = require(Paths.Shared.Utils.PartUtil)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local Binder = require(Paths.Shared.Binder)
local HousingController = require(Paths.Client.HousingController)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneController = require(Paths.Client.Zones.ZoneController)

local ATT_MODEL_INITALIZED = "Initialized"

local CFRAME_TWEEN_INFO = TweenInfo.new(0.001, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local ROTATION_ADDEND = math.rad(45)
local VALID_PLACEMENT_COLOR = Color3.fromRGB(55, 155, 255)
local INVALID_PLACEMENT_COLOR = Color3.fromRGB(255, 0, 0)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local colorPanel = SelectionPanel.new()
local furniturePanel = SelectionPanel.new()
local uiStateMachine = UIController.getStateMachine()

local templates: Folder = Paths.Templates.Housing
local models: Folder = Paths.Assets.Housing.Furniture

local screenGui: ScreenGui = Paths.UI.Housing

local placementControls: BillboardGui = screenGui.PlacementControls
local moveButton: TextButton = placementControls.Move
local rotateButton: TextButton = placementControls.Others.Buttons.Rotate
local acceptButton: TextButton = placementControls.Others.Buttons.Accept
local closeRemoveButton: TextButton = placementControls.Others.Buttons.CloseRemove

local editingSession = Maid.new()
local placementSession = Maid.new()

local player = Players.LocalPlayer
local character: Model?

local plot: Model?
local plotCFrame: CFrame?

local colorNameSelected: string
local colorNum: number
local name: string
local position: Vector3
local normal: Vector3
local rotationY: number
local color: { Color3? }
local model: Model
local uiColorSelected: { SetSelected: any? }
local colorToWidget: {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function isPartNotCollideable(part: BasePart)
    return part.Name == "Hitbox" or part.Name == "Spawn" or part.Transparency == 1
end

local function isModelColliding(model: Model)
    for _, part: BasePart in model:GetDescendants() do
        if part:IsA("BasePart") and not isPartNotCollideable(part) then
            for _, collidingPart: BasePart in workspace:GetPartsInPart(part) do
                if
                    not collidingPart:IsDescendantOf(model)
                    and collidingPart:IsDescendantOf(plot.Furniture)
                    and not isPartNotCollideable(collidingPart)
                then
                    return true
                end
            end
        end
    end

    return false
end

local function selectPaintColor(color: Color3 | string)
    color = tostring(color)

    local button = colorPanel:GetContainer():FindFirstChild(color) -- Some colors stored in data might get discontinued
    if button then
        button.ColorSelected.Visible = true
    end
end

local function deselectPaintColor(color: Color3 | string)
    color = tostring(color)

    local button = colorPanel:GetContainer():FindFirstChild(color) -- Some colors stored in data might get discontinued
    if button then
        colorPanel:GetContainer()[color].ColorSelected.Visible = false
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
local function applyColor()
    for _, part: BasePart in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart and part.Parent.Name == colorNameSelected then
            part.Color = color[colorNum]
        end
    end
end

-- Register UIStates
do
    --Edit State
    local function enterState(data)
        model = data.Object
        local heightOffset: CFrame = CFrame.new(0, model:GetExtentsSize().Y / 2, 0) * CFrame.new(0, 0.05, 0)

        local isNewObject = data.IsNewObject

        local selectionBox: SelectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = model
        selectionBox.Color3 = VALID_PLACEMENT_COLOR
        selectionBox.Parent = model
        placementSession:GiveTask(selectionBox)

        -- Modifiers
        local function calculateCf(oldCf, surfacePos)
            if normal == nil then
                normal = Vector3.new(0, 1, 0)
            end
            return HousingConstants.CalculateObjectCFrame(oldCf, surfacePos, normal)
        end

        local function applyCFrame()
            local cf = calculateCf(CFrame.new(position) * CFrame.Angles(0, rotationY, 0), position) * heightOffset
            TweenUtil.tween(model.PrimaryPart, CFRAME_TWEEN_INFO, {
                CFrame = cf,
            })

            if isModelColliding(model) then
                selectionBox.Color3 = INVALID_PLACEMENT_COLOR
            else
                selectionBox.Color3 = VALID_PLACEMENT_COLOR
            end
        end

        -- Initialize info
        do
            if isNewObject then
                normal = Vector3.new(0, 1, 0)
                rotationY = 0
                name = model.Name
                if color == nil then
                    color = {}
                end
                for i = 1, 10 do
                    if model:FindFirstChild("Color" .. i) then
                        local part = model:FindFirstChild("Color" .. i):FindFirstChildOfClass("BasePart")
                            or model:FindFirstChild("Color" .. i):FindFirstChildOfClass("MeshPart")

                        color[i] = part.Color
                    end
                end

                position = character:GetPivot().Position - Vector3.new(0, character:GetExtentsSize().Y / 2, 0)

                model:PivotTo(CFrame.new(position))
                model.Parent = plot.Furniture

                applyColor()
                applyCFrame() -- Just for the selection box

                placementSession:GiveTask(model)

                selectionBox.Color3 = INVALID_PLACEMENT_COLOR
            else
                local store = DataController.get("House.Furniture." .. model.Name)
                if color == nil then
                    color = {}
                end
                for i, color_ in store.Color do
                    color[i] = DataUtil.deserializeValue(color_, Color3)
                end

                rotationY = DataUtil.deserializeValue(store.Rotation, Vector3).Y
                position = model.PrimaryPart.Position - heightOffset.Position
                normal = DataUtil.deserializeValue(store.Normal, Vector3)
            end
        end

        -- Initialize model
        do
            if not model:GetAttribute(ATT_MODEL_INITALIZED) then -- Allows model to be tweened
                model:SetAttribute(ATT_MODEL_INITALIZED, true)

                local primaryPart = model.PrimaryPart
                for _, basePart in pairs(model:GetDescendants()) do
                    if basePart:IsA("BasePart") and basePart ~= primaryPart then
                        basePart.Anchored = false
                        PartUtil.weld(primaryPart, basePart)
                    end
                end
            end

            for _, basePart in pairs(model:GetDescendants()) do -- Makes model ehterial
                if basePart:IsA("BasePart") then
                    Binder.bind(basePart, "PreSelectedProps", {
                        CanTouch = basePart.CanTouch,
                        CanCollide = basePart.CanCollide,
                    })

                    basePart.CanCollide = false
                    basePart.CanTouch = false
                end
            end

            placementSession:GiveTask(function()
                for _, basePart in pairs(model:GetDescendants()) do -- Makes model ehterial
                    if basePart:IsA("BasePart") then
                        local preSelectedProps = Binder.getBinded(basePart, "PreSelectedProps")
                        basePart.CanTouch = preSelectedProps.CanTouch
                        basePart.CanCollide = preSelectedProps.CanCollide
                    end
                end
            end)
        end

        -- Placement controls
        do
            placementControls.Enabled = true
            placementControls.Adornee = model
            placementSession:GiveTask(function()
                placementControls.Enabled = false
                placementControls.Adornee = nil :: Instance
            end)

            -- Moving
            local moving

            local function closeMoving()
                -- RETURN: Can't close something that isn't open
                if not moving then
                    return
                end
                if DeviceUtil.isConsole() or DeviceUtil.isMobile then
                    CameraUtil.setCametaType(workspace.CurrentCamera, Enum.CameraType.Custom)
                end

                moving = false

                UserInputService.MouseIconEnabled = true
                placementControls.Others.Visible = true

                RunService:UnbindFromRenderStep("MoveObject")
            end

            placementSession:GiveTask(InputController.CursorUp:Connect(closeMoving))
            placementSession:GiveTask(closeMoving)

            placementSession:GiveTask(moveButton.MouseButton1Down:Connect(function()
                moving = true
                if DeviceUtil.isConsole() or DeviceUtil.isMobile then
                    CameraUtil.setCametaType(workspace.CurrentCamera, Enum.CameraType.Scriptable)
                end

                UserInputService.MouseIconEnabled = false
                placementControls.Others.Visible = false

                local ignore = { model, player.Character, plot:FindFirstChildOfClass("Model").NoPlace }
                for _, otherFurniture: Model in pairs(plot.Furniture:GetChildren()) do
                    if otherFurniture:IsA("Model") then
                        table.insert(ignore, otherFurniture.PrimaryPart)
                    end
                end

                RunService:BindToRenderStep("MoveObject", Enum.RenderPriority.First.Value, function()
                    local result = MouseUtil.getMouseTarget(ignore, true)
                    local target, newPosition = result.Instance, result.Position
                    if target and target:IsDescendantOf(plot) and newPosition then
                        position = newPosition
                        normal = result.Normal
                        applyCFrame()
                    end
                end)
            end))

            -- Rotating
            placementSession:GiveTask(rotateButton.MouseButton1Down:Connect(function()
                rotationY = rotationY + ROTATION_ADDEND
                applyCFrame()
            end))

            -- Accepting changes
            placementSession:GiveTask(acceptButton.MouseButton1Down:Connect(function()
                -- RETURN: Cannot place item that is colliding
                if selectionBox.Color3 == INVALID_PLACEMENT_COLOR then
                    return
                end

                if isNewObject then
                    local metadata = {
                        Name = name,
                        Position = plotCFrame:PointToObjectSpace(model.PrimaryPart.Position),
                        Rotation = Vector3.new(0, rotationY, 0),
                        Color = color,
                        Normal = normal,
                    }
                    Remotes.fireServer("PlaceHouseObject", "Furniture", metadata)
                else
                    local name_ = DataController.get("House.Furniture." .. model.Name).Name
                    local metadata = {
                        Name = name_,
                        Position = plotCFrame:PointToObjectSpace(model.PrimaryPart.Position),
                        Rotation = Vector3.new(0, rotationY, 0),
                        Color = color,
                        Normal = normal,
                    }
                    Remotes.fireServer("UpdateFurniture", model.Name, metadata)
                end

                uiStateMachine:Pop()
            end))

            -- Closing / Selling
            placementSession:GiveTask(closeRemoveButton.MouseButton1Down:Connect(function()
                if not isNewObject then
                    Remotes.fireServer("RemoveFurniture", model.Name)
                end

                uiStateMachine:Pop()
            end))
        end

        -- Cover Color
        --hide or show tabs depending on if the model has "Color"..i
        for i = 2, HousingConstants.MaxColors do
            if model:FindFirstChild("Color" .. i) == nil then
                if i > 5 then --TODO: make this dynamic in SelectionPanel element. If shown tabs is > 5 then 't show forwardarrow
                    colorPanel:HideForwardArrow()
                end
                colorPanel:HideTab("Color" .. i)
            else
                if i > 5 then --TODO: make this dynamic in SelectionPanel element. If shown tabs is <= 5 then don't show forwardarrow
                    colorPanel:ShowForwardArrow()
                end
                colorPanel:ShowTab("Color" .. i)
            end
        end

        local colorpicked = color[1]

        if uiColorSelected then
            uiColorSelected:SetSelected(false)
        end

        if colorToWidget[tostring(colorpicked)] then
            uiColorSelected = colorToWidget[tostring(colorpicked)]
            uiColorSelected:SetSelected(true)
        end

        colorNameSelected = "Color1"
        colorNum = 1
        colorPanel:OpenTab(colorNameSelected)
        ScreenUtil.inRight(colorPanel:GetContainer())
    end

    local function closeState()
        placementSession:Cleanup()
        ScreenUtil.outLeft(colorPanel:GetContainer())
    end

    local function minState()
        ScreenUtil.outLeft(colorPanel:GetContainer())
        placementControls.Enabled = false
    end

    local function openState()
        ScreenUtil.inRight(colorPanel:GetContainer())
        placementControls.Enabled = true
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.FurniturePlacement, {
        Boot = enterState,
        Shutdown = closeState,
        Maximize = openState,
        Minimize = minState,
    })

    --HouseEditor UI state
    local function enterHouseEdit(data)
        character = player.Character

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
        plotCFrame = CFrame.new(plot:WaitForChild("Origin").Position)

        editingSession:GiveTask(InputController.CursorDown:Connect(function(gameProcessedEvent)
            -- RETURN: Clicked something unrelated
            if gameProcessedEvent then
                return
            end

            -- Selecting an item to edit
            local result = MouseUtil.getMouseTarget({ player.Character }, true)
            local target = result.Instance

            if target and target:IsDescendantOf(plot.Furniture) then
                if string.find(target.Parent.Name, "Color") then
                    target = target.Parent
                end

                local model = target.Parent
                if uiStateMachine:GetState() == UIConstants.States.FurniturePlacement then
                    if uiStateMachine:GetData().Object == model then
                        return
                    else
                        uiStateMachine:Pop()
                    end
                end

                uiStateMachine:Push(UIConstants.States.FurniturePlacement, {
                    Object = model,
                    IsNewObject = false,
                })
            end
        end))

        placementSession:GiveTask(function()
            deselectPaintColor(color[1]) -- Reset colors
        end)
    end

    local function exitHouseEdit()
        plot:FindFirstChildOfClass("Model").NoPlace.Transparency = 1
        plot = nil
        character = nil
        editingSession:Cleanup()
        ScreenUtil.outDown(furniturePanel:GetContainer())
    end

    local function maximizeHouseEdit()
        ScreenUtil.inUp(furniturePanel:GetContainer())
    end

    local function minimizeHouseEdit()
        ScreenUtil.outDown(furniturePanel:GetContainer())
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.HouseEditor, {
        Boot = enterHouseEdit,
        Shutdown = exitHouseEdit,
        Maximize = maximizeHouseEdit,
        Minimize = minimizeHouseEdit,
    })

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

        local function setCategoryVisible(on: boolean)
            ObjectsFrame.Visible = on
            BackButton:GetButtonObject().Parent.Visible = on
            furniturePanel:GetContainer().Background.Back.ScrollingFrame.Visible = not on
        end

        local function getTotalPlaced(objectKey: string)
            local data = DataController.get("House.Furniture")
            local placed = 0

            for _, object in data do
                if object.Name == objectKey and object.FromDefault == nil then
                    placed += 1
                end
            end

            return placed
        end

        local function loadNewItems(tag: string)
            for i, v in pairs(ObjectsFrame:GetChildren()) do
                if not v:IsA("UIListLayout") then
                    v:Destroy()
                end
            end
            local objects = FurnitureConstants.GetObjectsFromTag(tag)
            for objectKey, objectInfo in objects do
                local modelTemplate = models[objectKey]
                local product = ProductUtil.getHouseObjectProduct("Furniture", objectKey)
                local objectWidget = Widget.diverseWidgetFromHouseObject("Furniture", objectKey)

                objectWidget:GetGuiObject().Parent = ObjectsFrame

                objectWidget.Pressed:Connect(function()
                    local isOwned = ProductController.hasProduct(product) or ProductUtil.isFree(product)
                    local count = ProductController.getProductCount(product)
                    local total = getTotalPlaced(objectKey)
                    if isOwned and count - total > 0 then
                        uiStateMachine:Push(UIConstants.States.FurniturePlacement, {
                            Object = modelTemplate:Clone(),
                            IsNewObject = true,
                        })
                    else
                        ProductController.prompt(product)
                    end
                end)
            end
            setCategoryVisible(true)
        end

        furniturePanel.TabChanged:Connect(function()
            setCategoryVisible(false)
        end)

        furniturePanel:GetContainer().Background.Back.ScrollingFrame.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

        local function addWidget(tabName: string, tag: string)
            furniturePanel:AddWidgetConstructor(tabName, tag, function(parent, maid)
                local widget = Widget.diverseWidget()
                widget:DisableIcon()
                widget:SetText(tag)

                widget.Pressed:Connect(function()
                    loadNewItems(tag)
                end)

                widget:Mount(parent)
                maid:GiveTask(widget)
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

        BackButton.Pressed:Connect(function()
            setCategoryVisible(false)
        end)

        setCategoryVisible(false)
    end
    -- Color Panel Setup
    do
        local template = templates.PaintTemplate:Clone()
        colorPanel:Mount(screenGui)

        colorPanel:SetAlignment("Left")
        colorPanel:SetSize(1)
        for i = 1, HousingConstants.MaxColors do
            colorPanel:AddTab("Color" .. i, Images.Icons.Paint)
        end

        colorPanel:OpenTab("Color1")
        colorPanel.ClosePressed:Connect(function()
            UIController:Remove(UIConstants.States.FurniturePlacement)
        end)
        template.Parent = colorPanel:GetContainer()

        colorToWidget = {}

        for colorName, colorData in pairs(FurnitureConstants.Colors) do
            local product = ProductUtil.getHouseColorProduct(colorName, colorData.ImageColor)
            local ColorWidget = Widget.diverseWidgetFromHouseColor(colorName, colorData.ImageColor)
            local ui = ColorWidget:GetGuiObject()
            ui.Name = colorName
            ui.Parent = template.Colors
            ui:SetAttribute("ColorValue", colorData.ImageColor)

            colorToWidget[tostring(colorData.ImageColor)] = ColorWidget

            local button = ui.imageButton
            local colorValue = colorData.ImageColor
            button.MouseButton1Down:Connect(function()
                local isOwned = ProductController.hasProduct(product) or ProductUtil.isFree(product)
                if isOwned then
                    colorNameSelected = colorPanel:GetOpenTabName()
                    colorNum = tonumber(string.sub(colorNameSelected, 6, 6))
                    if color ~= colorName then
                        if uiColorSelected then
                            uiColorSelected:SetSelected(false)
                        end
                        uiColorSelected = ColorWidget
                        uiColorSelected:SetSelected(true)
                        deselectPaintColor(color[1])
                        color[colorNum] = colorValue
                        selectPaintColor(colorValue)
                        applyColor()
                    end
                end
            end)
        end

        colorPanel.TabChanged:Connect(function(tabName: string)
            local colorId = tonumber(string.sub(tabName, 6, 6))
            local colorpicked = color[colorId]
            if uiColorSelected then
                uiColorSelected:SetSelected(false)
            end

            if colorToWidget[tostring(colorpicked)] then
                uiColorSelected = colorToWidget[tostring(colorpicked)]
                uiColorSelected:SetSelected(true)
            end
        end)

        ScreenUtil.outLeft(colorPanel:GetContainer())
        ScreenUtil.outDown(furniturePanel:GetContainer())
    end
end

return FurnitureEditingPage
