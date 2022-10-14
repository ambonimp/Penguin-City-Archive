local EditMode = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ObjectModule = require(Paths.Shared.HousingObjectData)
local HousingController = require(Paths.Client.HousingController)
local InputController = require(Paths.Client.Input.InputController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local PlayerData = require(Paths.Client.DataController)
local Remotes = require(Paths.Shared.Remotes)
local PartUtil = require(Paths.Shared.Utils.PartUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)

local ATTRIBUTE_IS_SETUP = "Setup"
local ATTRIBUTE_CAN_COLLIDE = "CanCollide"
local MOVE_TWEEN_INFO = TweenInfo.new(0.001, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local player = Players.LocalPlayer
local housingScreenItemMove: Frame = HousingScreen.itemMove
local housingScreenItemButtons: Frame = housingScreenItemMove.Frame.Center.Buttons
local moveButton: TextButton = housingScreenItemMove.Frame.Move.Button
local closeButton: TextButton = housingScreenItemButtons.Close.Button
local okayButton: TextButton = housingScreenItemButtons.Okay.Button
local rotateButton: TextButton = housingScreenItemButtons.Rotate.Button
local hasObjectMoved = false
local isMovingObject = false
local rotationDeg = 0
local objectType: "OldObject" | "NewObject" | nil
local colorSelected: Color3?
local lastPosition: Vector3?
local selectedModel: Model?
local startingCFrame: CFrame?
local itemData: {
    Id: number,
    Position: { [number]: number },
    Color: { [number]: number },
    Rotation: { [number]: number },
    Name: string,
}?

local function getDataColor()
    return Color3.fromRGB(itemData.Color[1], itemData.Color[2], itemData.Color[3])
end

local function getItemInData(item: Model): any | nil
    if item then
        local Id = item:GetAttribute(HousingConstants.ModelId)
        local objects = PlayerData.get("Igloo.Placements")
        for _, data in objects do
            if data.Id == Id then
                return data, data.Name
            end
        end
    end
    return nil
end
--should move to a mouse Util module when more mouse util is introduced

--sets up the model for tweening // only client sided
local function setupModel(model: Model)
    -- RETURN: Already been setup!
    if model:GetAttribute(ATTRIBUTE_IS_SETUP) then
        return
    end
    model:SetAttribute(ATTRIBUTE_IS_SETUP, true)
    for _, part: BasePart in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart then
            part.Anchored = false
            PartUtil.weld(model.PrimaryPart, part)
        end
    end
end

--sets the color of a model except primarypart and parts that can't be colored
local function setModelColor(model: Model, color: Color3)
    for _, part: BasePart in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart and part.Parent.Name == "CanColor" then
            part.Color = color
        end
    end
end

--resets to original/selected color of model
local function resetModel()
    if itemData then
        local color = colorSelected or getDataColor()

        for _, part: BasePart in (selectedModel:GetDescendants()) do
            if part:IsA("BasePart") and part ~= selectedModel.PrimaryPart and part.Parent.Name == "CanColor" then
                part.Color = color
                part.CanCollide = part:GetAttribute(ATTRIBUTE_CAN_COLLIDE)
            end
        end
    end
end

function EditMode.itemColorChanged(color: Color3)
    if selectedModel then
        colorSelected = color
        setModelColor(selectedModel, color)
    end
end

--selects the item and prepares variables for usage
local function itemSelected(item: Model)
    setupModel(item)
    startingCFrame = item:GetPivot()
    for _, part: BasePart | Seat in (item:GetDescendants()) do
        if part:IsA("BasePart") then
            if part:IsA("Seat") then
                part.Disabled = true
            end
            part:SetAttribute(ATTRIBUTE_CAN_COLLIDE, part.CanCollide)
            part.CanCollide = false
        end
    end
    selectedModel = item
    lastPosition = selectedModel:GetPivot().Position - Vector3.new(0, selectedModel:GetExtentsSize().Y / 2, 0)
    itemData = getItemInData(selectedModel)

    HousingScreen.itemSelected(item)
    HousingScreen.openColorEdit()
    HousingScreen.closeBottomEdit()
    HousingScreen.setDefaultColor(ObjectModule[item.Name].defaultColor)

    if objectType == "OldObject" then
        rotationDeg = itemData.Rotation[2]
        colorSelected = getDataColor()
        HousingScreen.changePaintSelected(getDataColor())
    elseif objectType == "NewObject" then
        rotationDeg = 0
        colorSelected = ObjectModule[item.Name].defaultColor
        HousingScreen.changePaintSelected(colorSelected)
    else
        error(("Unexpected objectType %s"):format(objectType))
    end
end

--resets selection to nothing
local function itemDeselected(item: Model, fromOld: boolean | nil)
    hasObjectMoved = false
    EditMode.cancelMove()
    resetModel()
    for _, part: Seat in (item:GetDescendants()) do
        if part:IsA("Seat") then
            part.Disabled = false
        end
    end
    if not fromOld then
        HousingScreen.closeColorEdit()
    end
    HousingScreen.itemDeselected(item)
    HousingScreen.openBottomEdit()
end

function EditMode.reset()
    if selectedModel then
        itemDeselected(selectedModel)
    end
    RunService:UnbindFromRenderStep("MoveObject")

    hasObjectMoved = false
    objectType = nil
    colorSelected = nil
    lastPosition = nil
    selectedModel = nil
    startingCFrame = nil
    isMovingObject = false
    rotationDeg = 0
    itemData = nil
end

function EditMode.cancelMove()
    selectedModel:PivotTo(startingCFrame)
end

function itemIsTouching(item: Model)
    for _, part: BasePart in item:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "Hitbox" and part.Transparency ~= 1 then
            local parts = workspace:GetPartsInPart(part)

            for _, newPart: BasePart in parts do
                if
                    not newPart:IsDescendantOf(item)
                    and newPart.Name ~= "Hitbox"
                    and newPart.Name ~= "Spawn"
                    and newPart.Transparency ~= 1
                then
                    return true
                end
            end
        end
    end

    return false
end

local function moveSelected(Position)
    if selectedModel then
        TweenUtil.tween(selectedModel.PrimaryPart, MOVE_TWEEN_INFO, {
            CFrame = CFrame.new(Position + Vector3.new(0, selectedModel:GetExtentsSize().Y / 2))
                * CFrame.Angles(0, math.rad(rotationDeg), 0),
        })
        --[[ selectedModel:PivotTo(
            CFrame.new(Position + Vector3.new(0, selectedModel:GetExtentsSize().Y / 2)) * CFrame.Angles(0, math.rad(rotationDeg), 0)
        )]]

        if itemIsTouching(selectedModel) then
            setModelColor(selectedModel, Color3.fromRGB(150, 0, 0))
        else
            setModelColor(selectedModel, Color3.fromRGB(0, 150, 0))
        end
    end
end

function EditMode.newObjectSelected(object: Model)
    local Pos = player.Character:GetPivot().Position
        - Vector3.new(0, player.Character:GetExtentsSize().Y / 2, 0)
        + Vector3.new(0, object:GetExtentsSize().Y / 2, 0)
    local NewCFrame = CFrame.new(Pos)

    object:PivotTo(NewCFrame)
    objectType = "NewObject"
    object.Parent = HousingController.currentHouse.Parent.Furniture

    itemSelected(object)
end

moveButton.MouseButton1Down:Connect(function()
    if selectedModel then
        isMovingObject = true
        RunService:BindToRenderStep("MoveObject", Enum.RenderPriority.First.Value, function()
            if isMovingObject then
                if lastPosition then
                    hasObjectMoved = true
                end
                local ignore = { selectedModel, HousingController.currentHouse.Spawn, player.Character }
                for _, v: Model in HousingController.currentHouse.Parent.Furniture:GetChildren() do
                    if v:IsA("Model") then
                        table.insert(ignore, v.PrimaryPart)
                    end
                end
                local result = MouseUtil.getMouseTarget(ignore, true)
                local Target, Position = result.Instance, result.Position
                if Target and Target:IsDescendantOf(HousingController.currentHouse.Parent) and Position and selectedModel then
                    lastPosition = Position
                    moveSelected(Position)
                end
            end
        end)
    end
end)

moveButton.MouseButton1Up:Connect(function()
    RunService:UnbindFromRenderStep("MoveObject")
    isMovingObject = false
end)

closeButton.MouseButton1Down:Connect(function()
    if objectType == "NewObject" then
        selectedModel:Destroy()
    elseif not hasObjectMoved then
        Remotes.fireServer("RemoveObject", selectedModel:GetAttribute(HousingConstants.ModelId), ObjectModule[selectedModel.Name].type)
    end
    EditMode.reset()
end)

rotateButton.MouseButton1Down:Connect(function()
    if selectedModel then
        rotationDeg = (rotationDeg + 45) % 360
        moveSelected(lastPosition)
    end
end)

okayButton.MouseButton1Down:Connect(function()
    if not itemIsTouching(selectedModel) then
        local cframe = selectedModel:GetPivot()
        local rotationVector = Vector3.new(0, rotationDeg, 0)
        local color = colorSelected
        startingCFrame = cframe
        if objectType == "NewObject" then
            Remotes.fireServer("NewObject", selectedModel.Name, ObjectModule[selectedModel.Name].type, cframe, rotationVector, color)
            selectedModel:Destroy()
        elseif objectType == "OldObject" then
            Remotes.fireServer(
                "ChangeObject",
                selectedModel:GetAttribute(HousingConstants.ModelId),
                cframe,
                rotationVector,
                color,
                selectedModel
            )
        end
        EditMode.reset()
        HousingScreen.openBottomEdit()
        HousingScreen.closeColorEdit()
    end
end)

InputController.CursorUp:Connect(function()
    if isMovingObject then
        RunService:UnbindFromRenderStep("MoveObject")
        isMovingObject = false
    end
end)

InputController.CursorDown:Connect(function()
    -- RETURN: Not in a fit state to be editing
    if not (HousingController.isEditing and HousingController.currentHouse) then
        return
    end
    local OldSelected = selectedModel
    if OldSelected then
        itemDeselected(OldSelected, true)
        if objectType == "NewObject" then
            selectedModel:Destroy()
            EditMode.reset()
            return
        end
    end

    local result = MouseUtil.getMouseTarget({ player.Character }, true)
    local target = result.Instance

    if target and target:IsDescendantOf(HousingController.currentHouse.Parent.Furniture) then
        if target.Parent.Name == "CanColor" then
            target = target.Parent
        end
        local model = target.Parent
        if OldSelected == model then
            EditMode.reset()
            return
        end

        objectType = "OldObject"
        itemSelected(model)
        setModelColor(model, Color3.fromRGB(150, 0, 0))
    else
        EditMode.reset()
    end
end)

return EditMode
