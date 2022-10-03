local UIScaleController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Limiter = require(Paths.Shared.Limiter)
local Signal = require(Paths.Shared.Signal)

local BASE_RESOLUTION = Vector2.new(1920, 1080) -- UI is edited using this aspect ratio

local initContainerSizes: { [Instance]: UDim2 } = {} -- Containers are children of ScreenGui's
local initUICornerRadi: { [UICorner]: UDim } = {} -- UICorners don't scale with UIScale, so we need something custom

local scale: number -- Allows for the retention of aspect ratios

local camera: Camera = Workspace.CurrentCamera

UIScaleController.ViewportSizeChanged = Signal.new()

local function scaleContainer(instance: Instance)
    instance.UIScale.Scale = scale

    local initSize = initContainerSizes[instance]
    instance.Size = UDim2.new(initSize.X.Scale / scale, initSize.X.Offset, initSize.Y.Scale / scale, initSize.Y.Offset)
end

local function scaleUICorner(instance: UICorner)
    local initCornerRadius = initUICornerRadi[instance]
    instance.CornerRadius = UDim.new(initCornerRadius.Scale, initCornerRadius.Offset * scale)
end

-- Initialize
local function updateScale()
    local viewportSize: Vector2 = camera.ViewportSize
    local prevScale = scale

    local ratio: Vector2 = viewportSize / BASE_RESOLUTION
    scale = if math.abs(1 - ratio.X) > math.abs(1 - ratio.Y) then ratio.X else ratio.Y

    for instance in initContainerSizes do
        scaleContainer(instance)
    end

    for instance in initUICornerRadi do
        scaleUICorner(instance)
    end

    if prevScale then -- Don't fire on initialization
        UIScaleController.ViewportSizeChanged:Fire(viewportSize)
    end
end

updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    Limiter.indecisive(script.Name, 1, updateScale)
end)

for _, descendant in Paths.UI:GetDescendants() do
    if descendant:IsA("UIScale") then
        local parent = descendant.Parent
        initContainerSizes[parent] = parent.Size
        scaleContainer(parent)
    elseif descendant:IsA("UICorner") then
        initUICornerRadi[descendant] = descendant.CornerRadius
        scaleUICorner(descendant)
    end
end

Paths.UI.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("UICorner") then
        initUICornerRadi[descendant] = descendant.CornerRadius
        scaleUICorner(descendant)
    end
end)

Paths.UI.DescendantRemoving:Connect(function(descendant)
    initUICornerRadi[descendant] = nil
end)

return UIScaleController
