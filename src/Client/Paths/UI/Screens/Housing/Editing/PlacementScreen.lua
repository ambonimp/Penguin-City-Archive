local PlacementScreen = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local HousingUtil = require(Paths.Shared.Utils.HousingUtil)
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
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local Binder = require(Paths.Shared.Binder)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneController = require(Paths.Client.Zones.ZoneController)

local ATTTRIBUTE_MODEL_INITALIZED = "Initialized"

local CFRAME_TWEEN_INFO = TweenInfo.new(0.001, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local ROTATION_ADDEND = math.rad(45)
local VALID_PLACEMENT_COLOR = Color3.fromRGB(55, 155, 255)
local INVALID_PLACEMENT_COLOR = Color3.fromRGB(255, 0, 0)
local ITEM_SELECT_DEBOUNCE = 0.1

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local colorPanel = SelectionPanel.new()
local uiStateMachine = UIController.getStateMachine()

local templates: Folder = Paths.Templates.Housing

local screenGui: ScreenGui = Paths.UI.Housing

local placementControls: BillboardGui = screenGui.PlacementControls
local moveButton: TextButton = placementControls.Move
local rotateButton: TextButton = placementControls.Others.Buttons.Rotate
local acceptButton: TextButton = placementControls.Others.Buttons.Accept
local closeRemoveButton: TextButton = placementControls.Others.Buttons.CloseRemove

local placementSession = Maid.new()

local player: Player = Players.LocalPlayer
local character: Model?

local plot: Model?
local plotCFrame: CFrame?

local lastItemPlaced: number
local colorNameSelected: string
local colorNum: number
local name: string
local position: Vector3
local normal: Vector3
local rotationY: number
local color: { Color3? }
local model: Model
local colorToWidget: {}
local lastModelOriginalCFrame: CFrame | nil
local colorWidgetSelected: Widget.Widget
-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function resetModel()
    if lastModelOriginalCFrame then
        if model:GetAttribute(ATTTRIBUTE_MODEL_INITALIZED) then
            model:SetAttribute(ATTTRIBUTE_MODEL_INITALIZED, false)

            model:PivotTo(lastModelOriginalCFrame)
        end
    end
end

local function initilizeModel() --initializes the current selected model
    if not model:GetAttribute(ATTTRIBUTE_MODEL_INITALIZED) then -- Allows model to be tweened
        model:SetAttribute(ATTTRIBUTE_MODEL_INITALIZED, true)

        local primaryPart = model.PrimaryPart
        for _, basePart in pairs(model:GetDescendants()) do
            if basePart:IsA("BasePart") and basePart ~= primaryPart then
                basePart.Anchored = false
                BasePartUtil.weld(primaryPart, basePart)
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

local function isPartNotCollideable(part: BasePart)
    return part.Name == "Hitbox" or part.Name == "Spawn" or part.Transparency == 1
end

local function isModelColliding(model1: Model)
    for _, part: BasePart in pairs(model1:GetDescendants()) do
        if part:IsA("BasePart") and not isPartNotCollideable(part) then
            for _, collidingPart: BasePart in pairs(workspace:GetPartsInPart(part)) do
                if
                    not collidingPart:IsDescendantOf(model1)
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
-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
local function paintModel(primedModel: Model, paintName: string, paintColor: Color3)
    for _, part: BasePart in pairs(primedModel:GetDescendants()) do
        local doPaint = part:IsA("BasePart") and part ~= model.PrimaryPart and part.Parent.Name == paintName
        if doPaint then
            part.Color = paintColor
        end
    end
end

-- Register Placement UIStates
do
    --Edit State
    local function boot(data: table)
        if DeviceUtil.isMobile() and (os.time() - (lastItemPlaced or 0) <= ITEM_SELECT_DEBOUNCE) then --prevents double clicking with mobile touches
            uiStateMachine:Remove(UIConstants.States.FurniturePlacement)
            return
        end

        if model then
            resetModel()
        end

        character = player.Character
        plot = data.Plot
        plotCFrame = data.PlotCFrame
        local isNewObject = data.IsNewObject
        model = data.Object

        local UP_VECTOR = Vector3.new(0, 1, 0)
        local modelData = FurnitureConstants.Objects[model.Name]

        if modelData == nil then
            local store = DataController.get("House.Furniture." .. model.Name)
            modelData = FurnitureConstants.Objects[store.Name]
        end

        --wall objects are rotated different depending on the normal, thus requiring some height adjustments depending on normal rotation
        local isWallObject: boolean = table.find(modelData.Tags, FurnitureConstants.Tags.Wall) and true or false
        local heightOffset: CFrame = CFrame.new(0, model:GetExtentsSize().Y / 2, 0)
            * (not isWallObject and CFrame.new(0, 0.05, 0) or CFrame.new(0, 0, -0.05))

        local selectionBox: SelectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = model
        selectionBox.Color3 = VALID_PLACEMENT_COLOR
        selectionBox.Parent = model
        placementSession:GiveTask(selectionBox)

        -- Modifiers
        local function applyCFrame()
            local cf = HousingUtil.CalculateObjectCFrame(
                CFrame.new(position) * CFrame.Angles(0, rotationY, 0),
                position,
                normal or UP_VECTOR
            ) * heightOffset
            if isWallObject then
                if normal == Vector3.new(0, 1, 0) then
                    local sizes = model:GetExtentsSize()
                    cf = cf * CFrame.Angles(math.rad(90), 0, 0) + Vector3.new(0, sizes.Z / 2, 0)
                end
            end
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
                for i = 1, HousingConstants.MaxColors do
                    if model:FindFirstChild("Color" .. i) then
                        local part = model:FindFirstChild("Color" .. i):FindFirstChildOfClass("BasePart")
                            or model:FindFirstChild("Color" .. i):FindFirstChildOfClass("MeshPart")
                            or model:FindFirstChild("Color" .. i):FindFirstChildOfClass("Part")
                        color[i] = part.Color
                    end
                end

                position = character:GetPivot().Position - Vector3.new(0, character:GetExtentsSize().Y / 2, 0)

                model:PivotTo(CFrame.new(position))
                model.Parent = plot.Furniture
                paintModel(model, colorNameSelected, color[colorNum])
                applyCFrame() -- Just for the selection box

                placementSession:GiveTask(model)

                selectionBox.Color3 = INVALID_PLACEMENT_COLOR
                lastModelOriginalCFrame = nil
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
                lastModelOriginalCFrame = model:GetPivot()
            end
        end

        initilizeModel()

        -- Placement controls
        do
            placementControls.Enabled = true
            placementControls.Adornee = model
            placementSession:GiveTask(function()
                placementControls.Enabled = false
                placementControls.Adornee = nil :: Instance
            end)

            -- Moving
            local moving: boolean = false

            local function closeMoving()
                -- RETURN: Can't close something that isn't open
                if not moving then
                    return
                end
                if DeviceUtil.isMobile() then
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
                if DeviceUtil.isMobile() then
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
                    if result then
                        local target, newPosition = result.Instance, result.Position
                        if target and target:IsDescendantOf(plot) and newPosition then
                            position = newPosition
                            normal = result.Normal
                            applyCFrame()
                        end
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
                lastItemPlaced = os.time()
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
                if i > colorPanel:GetTabAmountFromAlignment() then
                    colorPanel:HideForwardArrow()
                end
                colorPanel:HideTab("Color" .. i)
            else
                if i > colorPanel:GetTabAmountFromAlignment() then
                    colorPanel:ShowForwardArrow()
                end
                colorPanel:ShowTab("Color" .. i)
            end
        end

        if colorWidgetSelected then
            colorWidgetSelected:SetSelected(false)
        end

        if colorToWidget[color[1]] then
            colorWidgetSelected = colorToWidget[color[1]]
            colorWidgetSelected:SetSelected(true)
        end

        colorNameSelected = "Color1"
        colorNum = 1
        colorPanel:OpenTab(colorNameSelected)
        ScreenUtil.inRight(colorPanel:GetContainer())
    end

    local function shutdown()
        placementSession:Cleanup()
        ScreenUtil.outLeft(colorPanel:GetContainer())
    end

    local function maximize()
        ScreenUtil.inRight(colorPanel:GetContainer())
        placementControls.Enabled = true
    end

    local function minimize()
        ScreenUtil.outLeft(colorPanel:GetContainer())
        placementControls.Enabled = false
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.FurniturePlacement, {
        Boot = boot,
        Shutdown = shutdown,
        Maximize = maximize,
        Minimize = minimize,
    })
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
        uiStateMachine:Remove(UIConstants.States.FurniturePlacement)
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
                if colorWidgetSelected then
                    colorWidgetSelected:SetSelected(false)
                end
                colorNameSelected = colorPanel:GetOpenTabName()
                colorNum = tonumber(string.sub(colorNameSelected, 6, 6))
                if color ~= colorName then
                    ColorWidget:SetSelected(true)
                    colorWidgetSelected = ColorWidget
                    color[colorNum] = colorValue
                    paintModel(model, colorNameSelected, color[colorNum])
                end
            end
        end)
    end

    colorPanel.TabChanged:Connect(function(_old: string, tabName: string)
        local colorId = tonumber(string.sub(tabName, 6, 6))
        local colorpicked = color[colorId]
        colorNameSelected = tabName
        colorNum = colorId
        if colorWidgetSelected then
            colorWidgetSelected:SetSelected(false)
        end

        if colorToWidget[tostring(colorpicked)] then
            colorWidgetSelected = colorToWidget[tostring(colorpicked)]
            colorWidgetSelected:SetSelected(true)
        end
    end)

    ScreenUtil.outLeft(colorPanel:GetContainer())
end

ZoneController.ZoneChanging:Connect(function(old, new)
    if tostring(old.ZoneType) == tostring(player.UserId) and tostring(new.ZoneType) ~= tostring(player.UserId) then
        if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            uiStateMachine:Remove(UIConstants.States.HouseEditor)
        end
        if uiStateMachine:HasState(UIConstants.States.FurniturePlacement) then
            uiStateMachine:Remove(UIConstants.States.FurniturePlacement)
        end
    elseif tonumber(new.ZoneType) then --remove house setting state when entering house
        if uiStateMachine:HasState(UIConstants.States.PlotSettings) then
            uiStateMachine:Remove(UIConstants.States.PlotSettings)
        end
        if uiStateMachine:HasState(UIConstants.States.HouseSelectionUI) then
            uiStateMachine:Remove(UIConstants.States.HouseSelectionUI)
        end
    end
end)

return PlacementScreen
