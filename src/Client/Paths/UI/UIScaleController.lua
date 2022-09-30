local UIScaleController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local BASE_RESOLUTION = Vector2.new(1920, 1080) -- UI is edited using this aspect ratio

local initScalingProps: { [Instance]: any } = {}
local scale: Vector2
local minScale: number -- Allows for the retention of aspect ratios

local camera: Camera = Workspace.CurrentCamera

local applyScale: { [string]: (Instance) -> () } = {
    ["UIStroke"] = function(instance: UIStroke)
        local initThickness = initScalingProps[instance]
        if not initThickness then
            initThickness = instance.Thickness
            initScalingProps[instance] = initThickness
        end

        instance.Thickness = initThickness * minScale
    end,

    ["ScrollingFrame"] = function(instance: ScrollingFrame)
        local initThickness = initScalingProps[instance]
        if not initThickness then
            initThickness = instance.ScrollBarThickness
            initScalingProps[instance] = initThickness
        end

        instance.ScrollBarThickness = initThickness * scale.X
    end,

    ["UICorner"] = function(instance: UICorner)
        local initRadius = initScalingProps[instance]
        if not initRadius then
            initRadius = instance.CornerRadius
            initScalingProps[instance] = initRadius
        end

        instance.CornerRadius = UDim.new(initRadius.Scale, initRadius.Offset * minScale)
    end,

    ["UIPadding"] = function(instance: UIPadding)
        local initProperties = initScalingProps[instance]
        if not initProperties then
            initProperties = {
                PaddingBottom = instance.PaddingBottom,
                PaddingRight = instance.PaddingRight,
                PaddingLeft = instance.PaddingLeft,
                PaddingTop = instance.PaddingTop,
            }

            initScalingProps[instance] = initProperties
        end

        for property, initPadding: UDim in pairs(initProperties) do
            instance[property] = UDim.new(initPadding.Scale, initPadding.Offset * minScale)
        end
    end,

    ["UIListLayout"] = function(instance: UIListLayout)
        local initPadding = initScalingProps[instance]
        if not initPadding then
            initPadding = instance.Padding
            initScalingProps[instance] = initPadding
        end

        instance.Padding = UDim.new(initPadding.Scale, initPadding.Offset * minScale)
    end,

    ["UIGridLayout"] = function(instance: UIGridLayout)
        local initProperties = initScalingProps[instance]
        if not initProperties then
            initProperties = {
                CellSize = instance.CellSize,
                CellPadding = instance.CellPadding,
            }

            initScalingProps[instance] = initProperties
        end

        local initCellSize: UDim2 = initProperties.CellSize
        local initCellPadding: UDim2 = initProperties.CellPadding

        instance.CellSize =
            UDim2.new(initCellSize.X.Scale, initCellSize.X.Offset * minScale, initCellSize.Y.Scale, initCellSize.Y.Offset * minScale)

        instance.CellPadding = UDim2.new(
            initCellPadding.X.Scale,
            initCellPadding.X.Offset * minScale,
            initCellPadding.Y.Scale,
            initCellPadding.Y.Offset * minScale
        )
    end,
}

-- Initialize
local function registerInstance(instance: Instance)
    local modifier = applyScale[instance.ClassName]
    if modifier then
        modifier(instance)
    end
end

local function updateScale()
    scale = camera.ViewportSize / BASE_RESOLUTION
    minScale = if math.abs(1 - scale.X) > math.abs(1 - scale.Y) then scale.X else scale.Y

    for instance in pairs(initScalingProps) do
        applyScale[instance.ClassName](instance)
    end
end

updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

for _, descendant in ipairs(Paths.UI:GetDescendants()) do
    registerInstance(descendant)
end
Paths.UI.DescendantAdded:Connect(registerInstance)
Paths.UI.DescendantRemoving:Connect(function(descendant)
    initScalingProps[descendant] = nil
end)

return UIScaleController
