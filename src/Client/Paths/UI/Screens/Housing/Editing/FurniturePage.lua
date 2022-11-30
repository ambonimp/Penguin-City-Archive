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
local Button = require(Paths.Client.UI.Elements.Button)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local InputController = require(Paths.Client.Input.InputController)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local Images = require(Paths.Shared.Images.Images)
local FurnitureConstants = require(Paths.Shared.Constants.HouseObjects.FurnitureConstants)
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
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function FurnitureEditingPage.loadItems()
    for objectName, objectInfo in pairs(FurnitureConstants.Objects) do
        local modelTemplate = models[objectName]

        local objectButtonObject: ImageButton = templates.Object:Clone()
        objectButtonObject.Name = objectName

        local price = objectInfo.Price
        objectButtonObject.Price.Text = "$" .. price

        -- Temporary
        CameraUtil.lookAtModelInViewport(objectButtonObject.ViewportFrame, modelTemplate:Clone())

        local objectButton = Button.new(objectButtonObject)
        objectButton.Pressed:Connect(function()
            -- Validate
            uiStateMachine:Push(UIConstants.States.FurniturePlacement, {
                Object = modelTemplate:Clone(),
                IsNewObject = true,
            })
        end)

        objectButton:Mount(screenGui.Edit.Center.Furniture)
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
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.FurniturePlacement, function(data)
        model = data.Object
        local heightOffset: Vector3 = Vector3.new(0, model:GetExtentsSize().Y / 2, 0)

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
            local cf = calculateCf(CFrame.new(position) * CFrame.Angles(0, rotationY, 0), position)
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

                position = character:GetPivot().Position - Vector3.new(0, character:GetExtentsSize().Y / 2, 0) + heightOffset

                model:PivotTo(CFrame.new(position))
                model.Parent = plot.Furniture

                applyColor()
                applyCFrame() -- Just for the selection box

                placementSession:GiveTask(model)
            else
                local store = DataController.get("House.Furniture." .. model.Name)
                if color == nil then
                    color = {}
                end
                for i, color_ in store.Color do
                    color[i] = DataUtil.deserializeValue(color_, Color3)
                end

                rotationY = DataUtil.deserializeValue(store.Rotation, Vector3).Y
                position = model.PrimaryPart.Position
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

                moving = false

                UserInputService.MouseIconEnabled = true
                placementControls.Others.Visible = true

                RunService:UnbindFromRenderStep("MoveObject")
            end

            placementSession:GiveTask(InputController.CursorUp:Connect(closeMoving))
            placementSession:GiveTask(closeMoving)

            placementSession:GiveTask(moveButton.MouseButton1Down:Connect(function()
                moving = true

                UserInputService.MouseIconEnabled = false
                placementControls.Others.Visible = false

                local ignore = { model, player.Character }
                for _, otherFurniture: Model in pairs(plot.Furniture:GetChildren()) do
                    if otherFurniture:IsA("Model") then
                        table.insert(ignore, otherFurniture.PrimaryPart)
                    end
                end

                -- ty joel
                local offset = position - (MouseUtil.getMouseTarget(ignore, true).Position + heightOffset)
                RunService:BindToRenderStep("MoveObject", Enum.RenderPriority.First.Value, function()
                    local result = MouseUtil.getMouseTarget(ignore, true)
                    local target, newPosition = result.Instance, result.Position
                    if target and target:IsDescendantOf(plot) and newPosition then
                        position = newPosition + heightOffset + offset
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

                local metadata = {
                    Name = name,
                    Position = plotCFrame:PointToObjectSpace(position),
                    Rotation = Vector3.new(0, rotationY, 0),
                    Color = color,
                    Normal = normal,
                }

                if isNewObject then
                    Remotes.fireServer("PlaceHouseObject", "Furniture", metadata)
                else
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

        for i = 1, 10 do
            colorPanel:RemoveTab("Color" .. i)
        end
        for i = 1, 10 do
            if model:FindFirstChild("Color" .. i) then
                colorPanel:AddTab("Color" .. i, Images.Icons.Paint)
            end
        end

        colorNameSelected = "Color1"
        colorNum = 1
        colorPanel:OpenTab(colorNameSelected)
        ScreenUtil.inLeft(colorPanel:GetContainer())
    end, function()
        placementSession:Cleanup()
        ScreenUtil.outLeft(colorPanel:GetContainer())
    end)

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HouseEditor, function(data)
        character = player.Character

        -- See if we can get plot
        local zoneOwner = ZoneUtil.getHouseInteriorZoneOwner(ZoneController.getCurrentZone())
        local thisPlot = HousingController.getPlotFromOwner(zoneOwner, HousingConstants.InteriorType)

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
                if target.Parent.Name == colorNameSelected then
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
    end, function()
        if not uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            plot = nil
            character = nil
            editingSession:Cleanup()
        end
    end)

    -- Color Panel Setup
    do
        local template = templates.PaintTemplate:Clone()
        colorPanel:Mount(screenGui)

        colorPanel:SetAlignment("Left")
        colorPanel:SetSize(1)

        colorPanel.ClosePressed:Connect(function()
            -- toggleEditMode(false)
        end)
        template.Parent = colorPanel:GetContainer()
        -- Initialize colors
        for _, color_ in pairs(FurnitureConstants.Colors) do
            local button = templates.PaintColor:Clone()
            button.Name = tostring(color_)
            button.ImageColor3 = color_
            button.Parent = template.Colors
            button:SetAttribute("ColorValue", color_)
            button.ZIndex = 50

            local colorName = button.Name
            local colorValue = color_
            button.MouseButton1Down:Connect(function()
                colorNameSelected = colorPanel:GetOpenTabName()
                colorNum = tonumber(string.sub(colorNameSelected, 6, 6))
                if color ~= colorName then
                    deselectPaintColor(color[1])
                    color[colorNum] = colorValue
                    selectPaintColor(colorValue)
                    applyColor()
                end
            end)
        end

        ScreenUtil.outLeft(colorPanel:GetContainer())
    end
end

return FurnitureEditingPage
