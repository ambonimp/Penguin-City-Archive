local UIScaleController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Limiter = require(Paths.Shared.Limiter)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local Signal = require(Paths.Shared.Signal)

local BASE_RESOLUTION = Vector2.new(1920, 1080) -- UI is edited using this aspect ratio
local LIMITER_KEY = "UIScaleResolution"
local LIMITER_TIMEFRAME = 0.2

type InstanceValuePair = {
    Instance: Instance,
    Value: any,
}
type UIScaleData = {
    Container: InstanceValuePair,
    SpecialInstances: { InstanceValuePair },
}

-------------------------------------------------------------------------------
-- Private Members
-------------------------------------------------------------------------------

local uiScaleDatas: { [UIScale]: UIScaleData } = {}
local scale: number -- Allows for the retention of aspect ratios
local camera: Camera = Workspace.CurrentCamera

-------------------------------------------------------------------------------
-- PublicMembers
-------------------------------------------------------------------------------

UIScaleController.ScaleChanged = Signal.new()

-------------------------------------------------------------------------------
-- Instance creation
-------------------------------------------------------------------------------

local function handleTextObject(textObject: TextLabel | TextBox | TextButton)
    -- RETURN: Does not need scaling
    local needsScaling = textObject.TextScaled == false
    if not needsScaling then
        return
    end

    -- RETURN: Already has UITextSizeConstraint
    if textObject:FindFirstChildWhichIsA("UITextSizeConstraint") then
        return
    end

    -- Needs custom scaling!
    local uiTextSizeConstraint = Instance.new("UITextSizeConstraint")
    uiTextSizeConstraint.MaxTextSize = textObject.TextSize
    uiTextSizeConstraint.Parent = textObject

    textObject.TextScaled = true
end

-------------------------------------------------------------------------------
-- Instance updating
-------------------------------------------------------------------------------

local classnameToUpdater: { [string]: (instance: Instance, value: any, toScale: number?) -> nil } = {
    UICorner = function(instance: UICorner, initUDim: UDim, toScale: number?)
        toScale = toScale or scale

        instance.CornerRadius = UDim.new(initUDim.Scale, initUDim.Offset * toScale)
    end,
    UITextSizeConstraint = function(instance: UITextSizeConstraint, initTextSize: number, toScale: number?)
        toScale = toScale or scale

        instance.MaxTextSize = initTextSize * toScale
    end,
}

-- Updates the scope of a UIScale to a new scale
function UIScaleController.updateUIScale(uiScale: UIScale, toScale: number?)
    toScale = toScale or scale

    -- UIScale
    uiScale.Scale = toScale

    -- UIScale Container
    local data = uiScaleDatas[uiScale]
    local initSize: UDim2 = data.Container.Value
    data.Container.Instance.Size = UDim2.new(initSize.X.Scale / toScale, initSize.X.Offset, initSize.Y.Scale / toScale, initSize.Y.Offset)

    -- Special Instances
    for _, instanceValuePair in pairs(data.SpecialInstances) do
        classnameToUpdater[instanceValuePair.Instance.ClassName](instanceValuePair.Instance, instanceValuePair.Value, toScale)
    end
end

local function updateScale()
    local viewportSize: Vector2 = camera.ViewportSize

    local ratio: Vector2 = viewportSize / BASE_RESOLUTION
    scale = if math.abs(1 - ratio.X) > math.abs(1 - ratio.Y) then ratio.X else ratio.Y

    for uiScale, _ in pairs(uiScaleDatas) do
        UIScaleController.updateUIScale(uiScale)
    end

    UIScaleController.ScaleChanged:Fire(scale)
end

-------------------------------------------------------------------------------
-- Public Methods
-------------------------------------------------------------------------------

function UIScaleController.getScale()
    return scale
end

-------------------------------------------------------------------------------
-- Instance caching
-------------------------------------------------------------------------------

local classnameToCallback: { [string]: (instance: Instance) -> nil } = {
    TextLabel = handleTextObject,
    TextButton = handleTextObject,
    TextBox = handleTextObject,
}

local classnameToPair: { [string]: (instance: Instance) -> InstanceValuePair } = {
    UICorner = function(instance: UICorner)
        return {
            Instance = instance,
            Value = instance.CornerRadius,
        }
    end,
    UITextSizeConstraint = function(instance: UITextSizeConstraint)
        return {
            Instance = instance,
            Value = instance.MaxTextSize,
        }
    end,
}

local function specialChecker(descendant: Instance)
    return (classnameToPair[descendant.ClassName] or classnameToCallback[descendant.ClassName]) and true or false
end

local function specialAdder(descendant: Instance, uiScale: UIScale)
    local pairCreator = classnameToPair[descendant.ClassName]
    if pairCreator then
        local instanceValuePair = pairCreator(descendant)
        table.insert(uiScaleDatas[uiScale].SpecialInstances, instanceValuePair)

        local updater = classnameToUpdater[descendant.ClassName]
        updater(descendant, instanceValuePair.Value)

        return
    end

    local callback = classnameToCallback[descendant.ClassName]
    if callback then
        callback(descendant)
        return
    end

    error(("Cannot handle %s (%s)"):format(descendant.ClassName, descendant:GetFullName()))
end

-- We got a new UIScale in the building!
local function newUIScale(uiScale: UIScale)
    -- Init Data
    local thisSize: UDim2 = uiScale.Parent.Size
    local thisScale = uiScale.Scale

    local data: UIScaleData = {
        Container = {
            Instance = uiScale.Parent,
            Value = UDim2.new(thisSize.X.Scale * thisScale, thisSize.X.Offset, thisSize.Y.Scale * thisScale, thisSize.Y.Offset), -- Convert from developer
        },
        SpecialInstances = {},
    }
    uiScaleDatas[uiScale] = data

    -- Keep track of special instances
    DescendantLooper.add(specialChecker, function(descendant)
        specialAdder(descendant, uiScale)
    end, { data.Container.Instance }, false)

    -- Handle removal
    uiScale.AncestryChanged:Connect(function(_, parent)
        if not parent then
            uiScaleDatas[uiScale] = nil
        end
    end)

    -- Init
    UIScaleController.updateUIScale(uiScale)
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

-- Internally setup scaling
updateScale()

-- Update scale when viewport changes
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    Limiter.indecisive(LIMITER_KEY, LIMITER_TIMEFRAME, updateScale)
end)

-- Get UIScales
DescendantLooper.add(function(descendant)
    return descendant:IsA("UIScale")
end, function(descendant)
    newUIScale(descendant)
end, { Paths.UI }, false)

return UIScaleController
