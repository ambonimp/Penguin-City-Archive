local EditMode = {}

local Paths = require(script.Parent.Parent)
local HousingController = require(Paths.Client.HousingController)
local InputController = require(Paths.Client.Input.InputController)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local PlayerData = require(Paths.Client.DataController)
local Remotes = require(Paths.Shared.Remotes)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera

local MoveTweenInfo = TweenInfo.new(0.146, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local LastPosition = nil
local ModelColors = nil
local ModelSelected = nil
local StartingPosition = nil
local MovingObject = false
local Rotation = 0
local ItemData = nil

local function getItemInData(item: Model)
    print("item model:", item)
    if item then
        local Id = item:GetAttribute("Id")
        print(Id)
        local objects = PlayerData.get("Igloo.Placements")
        print("data", objects)
        for name, data in objects do
            if data.Id == Id then
                print("Found")
                return data, name
            end
        end
    end
    return nil
end
--should move to a mouse Util module when more mouse util is introduced
local function getMouseTarget(ignore: Array<Instance>)
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

--sets the color of a model except primarypart
local function setModelColor(model: Model, color: Color3)
    for _, part in (model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= model.PrimaryPart then
            if ModelColors == nil then
                ModelColors = {}
                ModelColors[part] = part.Color
            end
            part.Color = color
        end
    end
end

--resets to original/selected color of model
local function resetModel()
    if ItemData then
        local color = Color3.fromRGB(ItemData.Color[1], ItemData.Color[2], ItemData.Color[3])

        for _, part in (ModelSelected:GetDescendants()) do
            if part:IsA("BasePart") and part ~= ModelSelected.PrimaryPart then
                part.Color = color
                part.CanCollide = part:GetAttribute("CanCollide")
            end
        end
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
    Rotation = ItemData.Rotation[2]
    HousingScreen.ItemSelected(item)
    HousingScreen.openColorEdit()
    HousingScreen.closeBottomEdit()
end

--resets selection to nothing
local function ItemDeselected(item: Model)
    for _, part in (item:GetDescendants()) do
        if part:IsA("Seat") then
            part.Disabled = false
        end
    end
    HousingScreen.ItemDeselected(item)
    HousingScreen.openBottomEdit()
    HousingScreen.closeColorEdit()
end

function EditMode.Reset()
    if ModelSelected then
        ItemDeselected(ModelSelected)
        resetModel()
        EditMode.CancelMove()
        HousingScreen.ItemDeselected(ModelSelected)
    end
    ModelSelected = nil
    ModelColors = nil
    RunService:UnbindFromRenderStep("MoveObject")
    MovingObject = false
    HousingScreen.closeColorEdit()
end

function EditMode.CancelMove()
    ModelSelected:PivotTo(StartingPosition)
end

function ItemIsTouching(item: Model)
    local parts = workspace:GetPartsInPart(item.PrimaryPart)

    for _, part in parts do
        if not part:IsDescendantOf(item) and part.Name ~= "Hitbox" and part.Name ~= "Spawn" then
            return true
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

HousingScreen.itemMove.Frame.Move.Button.MouseButton1Down:Connect(function()
    if ModelSelected then
        MovingObject = true
        RunService:BindToRenderStep("MoveObject", Enum.RenderPriority.First.Value, function()
            if MovingObject then
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
    EditMode.Reset()
end)

HousingScreen.itemMove.Frame.Center.Buttons.Rotate.Button.MouseButton1Down:Connect(function()
    if ModelSelected and ItemData then
        Rotation += 45
        if Rotation >= 360 then
            Rotation = 0
        end
        ItemData.Rotation[2] = Rotation
        moveSelected(LastPosition)
    end
end)

HousingScreen.itemMove.Frame.Center.Buttons.Okay.Button.MouseButton1Down:Connect(function()
    if not ItemIsTouching(ModelSelected) then
        local CFram = ModelSelected:GetPivot()
        local Rot = Vector3.new(0, Rotation, 0)
        local Color = Color3.new(ItemData.Color[1], ItemData.Color[2], ItemData.Color[3])
        StartingPosition = CFram
        Remotes.fireServer("ChangeObject", ModelSelected:GetAttribute("Id"), CFram, Rot, Color, ModelSelected)
        EditMode.Reset()
        HousingScreen.openBottomEdit()
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
            EditMode.Reset()
        end
        local Target = getMouseTarget({ Player.Character })

        if Target and Target:IsDescendantOf(HousingController.CurrentHouse.Parent.Furniture) then
            if Target.Parent.Name == "CanColor" then
                Target = Target.Parent
            end
            local Model = Target.Parent
            if OldSelected == Model then
                ItemDeselected(Model)
                return
            end
            setModelColor(Model, Color3.fromRGB(150, 0, 0))
            ItemSelected(Model)
        end
    end
end)

return EditMode
