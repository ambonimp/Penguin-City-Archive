local EditMode = {}
--services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
--modules
local Paths = require(script.Parent.Parent)
local ObjectModule = require(Paths.Shared.HousingObjectData)
local HousingController = require(Paths.Client.HousingController)
local InputController = require(Paths.Client.Input.InputController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local PlayerData = require(Paths.Client.DataController)
local Remotes = require(Paths.Shared.Remotes)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MoveTweenInfo = TweenInfo.new(0.146, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local ObjectMoved = false
local ObjectType = nil
local ColorSelected = nil
local LastPosition = nil
local ModelSelected = nil
local StartingPosition = nil
local MovingObject = false
local Rotation = 0
local ItemData = nil

local function getItemInData(item: Model)
    if item then
        local Id = item:GetAttribute("Id")
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
local function getMouseTarget(ignore: Array<Instance>)
    for _, v in HousingController.CurrentHouse.Parent.Furniture:GetChildren() do
        table.insert(ignore, v.PrimaryPart)
    end
    local cursorPosition = UserInputService:GetMouseLocation()

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignore or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local CameraRay = workspace.CurrentCamera:ViewportPointToRay(cursorPosition.X, cursorPosition.Y, 0)

    local raycastResult = workspace:Raycast(Camera.CFrame.Position, CameraRay.Direction * 50, raycastParams)

    if raycastResult then
        return raycastResult.Instance, raycastResult.Position, raycastResult.Position
    else
        return nil
    end
end

--sets up the model for tweening // only client sided
local function SetUpModel(model: Model)
    if model:GetAttribute("Setup") then
        return
    end
    model:SetAttribute("Setup", true)
    for _, part in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart then
            part.Anchored = false
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = model.PrimaryPart
            weld.Part1 = part
            weld.Parent = part
        end
    end
end

--sets the color of a model except primarypart and parts that can't be colored
local function setModelColor(model: Model, color: Color3)
    for _, part in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart and part.Parent.Name == "CanColor" then
            part.Color = color
        end
    end
end

--resets to original/selected color of model
local function resetModel()
    if ItemData then
        local color = ColorSelected or Color3.fromRGB(ItemData.Color[1], ItemData.Color[2], ItemData.Color[3])

        for _, part in (ModelSelected:GetDescendants()) do
            if part:IsA("BasePart") and part ~= ModelSelected.PrimaryPart and part.Parent.Name == "CanColor" then
                part.Color = color
                part.CanCollide = part:GetAttribute("CanCollide")
            end
        end
    end
end

function EditMode.ItemColorChanged(color: Color3)
    if ModelSelected then
        ColorSelected = color
        setModelColor(ModelSelected, color)
    end
end

--selects the item and prepares variables for usage
local function ItemSelected(item: Model)
    SetUpModel(item)
    StartingPosition = item:GetPivot()
    for _, part in (item:GetDescendants()) do
        if part:IsA("BasePart") then
            if part:IsA("Seat") then
                part.Disabled = true
            end
            part:SetAttribute("CanCollide", part.CanCollide)
            part.CanCollide = false
        end
    end
    ModelSelected = item
    LastPosition = ModelSelected:GetPivot().Position - Vector3.new(0, ModelSelected:GetExtentsSize().Y / 2, 0)
    ItemData = getItemInData(ModelSelected)

    HousingScreen.ItemSelected(item)
    HousingScreen.openColorEdit()
    HousingScreen.closeBottomEdit()
    HousingScreen.SetDefaultColor(ObjectModule[item.Name].defaultColor)

    if ObjectType == "OldObject" then
        Rotation = ItemData.Rotation[2]
        ColorSelected = Color3.fromRGB(ItemData.Color[1], ItemData.Color[2], ItemData.Color[3])
        HousingScreen.ChangePaintSelected(Color3.fromRGB(ItemData.Color[1], ItemData.Color[2], ItemData.Color[3]))
    elseif ObjectType == "NewObject" then
        Rotation = 0
        ColorSelected = ObjectModule[item.Name].defaultColor
        HousingScreen.ChangePaintSelected(ColorSelected)
    end
end

--resets selection to nothing
local function ItemDeselected(item: Model, fromOld: boolean | nil)
    ObjectMoved = false
    EditMode.CancelMove()
    resetModel()
    for _, part in (item:GetDescendants()) do
        if part:IsA("Seat") then
            part.Disabled = false
        end
    end
    if not fromOld then
        HousingScreen.closeColorEdit()
    end
    HousingScreen.ItemDeselected(item)
    HousingScreen.openBottomEdit()
end

function EditMode.Reset()
    if ModelSelected then
        ItemDeselected(ModelSelected)
    end
    RunService:UnbindFromRenderStep("MoveObject")

    ObjectMoved = false
    ObjectType = nil
    ColorSelected = nil
    LastPosition = nil
    ModelSelected = nil
    StartingPosition = nil
    MovingObject = false
    Rotation = 0
    ItemData = nil
end

function EditMode.CancelMove()
    ModelSelected:PivotTo(StartingPosition)
end

function ItemIsTouching(item: Model)
    for _, part in item:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "Hitbox" and part.Transparency ~= 1 then
            local parts = workspace:GetPartsInPart(part)

            for _, newPart in parts do
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
    if ModelSelected then
        TweenUtil.tween(ModelSelected.PrimaryPart, MoveTweenInfo, {
            CFrame = CFrame.new(Position + Vector3.new(0, ModelSelected:GetExtentsSize().Y / 2)) * CFrame.Angles(0, math.rad(Rotation), 0),
        })
        --[[ ModelSelected:PivotTo(
            CFrame.new(Position + Vector3.new(0, ModelSelected:GetExtentsSize().Y / 2)) * CFrame.Angles(0, math.rad(Rotation), 0)
        )]]

        if ItemIsTouching(ModelSelected) then
            setModelColor(ModelSelected, Color3.fromRGB(150, 0, 0))
        else
            setModelColor(ModelSelected, Color3.fromRGB(0, 150, 0))
        end
    end
end

function EditMode.NewObjectSelected(object: Model)
    local Pos = Player.Character:GetPivot().Position
        - Vector3.new(0, Player.Character:GetExtentsSize().Y / 2, 0)
        + Vector3.new(0, object:GetExtentsSize().Y / 2, 0)
    local NewCFrame = CFrame.new(Pos)

    object:PivotTo(NewCFrame)
    ObjectType = "NewObject"
    object.Parent = HousingController.CurrentHouse.Parent.Furniture

    ItemSelected(object)
end

HousingScreen.itemMove.Frame.Move.Button.MouseButton1Down:Connect(function()
    if ModelSelected then
        MovingObject = true
        RunService:BindToRenderStep("MoveObject", Enum.RenderPriority.First.Value, function()
            if MovingObject then
                if LastPosition then
                    ObjectMoved = true
                end
                local Target, Position = getMouseTarget({ ModelSelected, HousingController.CurrentHouse.Spawn, Player.Character })

                if Target and Target:IsDescendantOf(HousingController.CurrentHouse.Parent) and Position and ModelSelected then
                    LastPosition = Position
                    moveSelected(Position)
                end
            end
        end)
    end
end)

HousingScreen.itemMove.Frame.Center.Buttons.Close.Button.MouseButton1Down:Connect(function()
    if ObjectType == "NewObject" then
        ModelSelected:Destroy()
    elseif not ObjectMoved then
        Remotes.fireServer("RemoveObject", ModelSelected:GetAttribute("Id"), ObjectModule[ModelSelected.Name].type)
    end
    EditMode.Reset()
end)

HousingScreen.itemMove.Frame.Center.Buttons.Rotate.Button.MouseButton1Down:Connect(function()
    if ModelSelected then
        Rotation += 45
        if Rotation >= 360 then
            Rotation = 0
        end
        moveSelected(LastPosition)
    end
end)

HousingScreen.itemMove.Frame.Center.Buttons.Okay.Button.MouseButton1Down:Connect(function()
    if not ItemIsTouching(ModelSelected) then
        local CFram = ModelSelected:GetPivot()
        local Rot = Vector3.new(0, Rotation, 0)
        local Color = ColorSelected
        StartingPosition = CFram
        if ObjectType == "NewObject" then
            Remotes.fireServer("NewObject", ModelSelected.Name, ObjectModule[ModelSelected.Name].type, CFram, Rot, Color)
            ModelSelected:Destroy()
        elseif ObjectType == "OldObject" then
            Remotes.fireServer("ChangeObject", ModelSelected:GetAttribute("Id"), CFram, Rot, Color, ModelSelected)
        end
        EditMode.Reset()
        HousingScreen.openBottomEdit()
        HousingScreen.closeColorEdit()
    end
end)

HousingScreen.itemMove.Frame.Move.Button.MouseButton1Up:Connect(function()
    RunService:UnbindFromRenderStep("MoveObject")
    MovingObject = false
end)

InputController.CursorUp:Connect(function()
    if MovingObject then
        RunService:UnbindFromRenderStep("MoveObject")
        MovingObject = false
    end
end)

InputController.CursorDown:Connect(function()
    if HousingController.isEditing and HousingController.CurrentHouse then
        local OldSelected = ModelSelected
        if OldSelected then
            ItemDeselected(OldSelected, true)
            if ObjectType == "NewObject" then
                ModelSelected:Destroy()
                EditMode.Reset()
                return
            end
        end
        local Target = getMouseTarget({ Player.Character })

        if Target and Target:IsDescendantOf(HousingController.CurrentHouse.Parent.Furniture) then
            if Target.Parent.Name == "CanColor" then
                Target = Target.Parent
            end
            local Model = Target.Parent
            if OldSelected == Model then
                EditMode.Reset()
                return
            end

            ObjectType = "OldObject"
            ItemSelected(Model)
            setModelColor(Model, Color3.fromRGB(150, 0, 0))
        else
            EditMode.Reset()
        end
    end
end)

return EditMode
