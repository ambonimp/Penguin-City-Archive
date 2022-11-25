local InstanceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)

local FADE_CLASSNAME_BY_PROPERTY = {
    Transparency = { "BasePart", "UIStroke", "Decal" },
    BackgroundTransparency = { "GuiObject" },
    TextTransparency = { "TextLabel", "TextButton" },
    TextStrokeTransparency = { "TextLabel", "TextButton" },
    ImageTransparency = { "ImageLabel", "ImageButton", "ViewportFrame" },
}
local FADE_TWEEN_INFO = TweenInfo.new(0.5)
local ATTRIBUTE_FADE_FORMAT = "_InstanceUtilFade_%s"

-- Wrapper for creating an instance and defining some basic property values
function InstanceUtil.new(className, name: string, parent: Instance)
    local instance = Instance.new(className)
    instance.Name = name
    instance.Parent = parent
    return instance
end

-- Wrapper for creating an instance with property values and children ideally in one line
function InstanceUtil.tree(class: string, props: { [string]: any }, children: { Instance }?): Instance
    local instance = Instance.new(class)
    for property, value in pairs(props) do
        instance[property] = value
    end

    if children then
        for _, child in pairs(children) do
            child.Parent = instance
        end
    end

    return instance
end

function InstanceUtil.setProperties(instance: Instance, propertyTable: { [string]: any })
    for propertyName, propertyValue in pairs(propertyTable) do
        instance[propertyName] = propertyValue
    end
end

function InstanceUtil.findFirstDescendant(instance: Instance, searchingFor: string): Instance?
    for _, descendant in pairs(instance:GetDescendants()) do
        if descendant.Name == searchingFor then
            return descendant
        end
    end
end

-- Returns children that checker(child) == true
function InstanceUtil.getChildren(instance: Instance, checker: (child: Instance) -> boolean)
    local children = {}
    for _, child in pairs(instance:GetChildren()) do
        if checker(child) then
            table.insert(children, child)
        end
    end
    return children
end

-- Returns descendants that checker(descendant) == true
function InstanceUtil.getDescendants(instance: Instance, checker: (descendant: Instance) -> boolean)
    local descendants = {}
    for _, descendant in pairs(instance:GetDescendants()) do
        if checker(descendant) then
            table.insert(descendants, descendant)
        end
    end
    return descendants
end

function InstanceUtil.convert(instance: Instance, toClassName: string)
    local newInstance = Instance.new(toClassName)
    newInstance.Name = instance.Name
    newInstance.Parent = instance.Parent

    for _, child in pairs(instance:GetChildren()) do
        child.Parent = newInstance
    end

    instance:Destroy()
    return newInstance
end

local function fade(instance: Instance, fadeProperty: string, visible: boolean, tweenInfo: TweenInfo?)
    tweenInfo = tweenInfo or FADE_TWEEN_INFO

    -- Cache
    local attributeName = ATTRIBUTE_FADE_FORMAT:format(fadeProperty)
    local cachedValue = instance:GetAttribute(attributeName)
    if not cachedValue then
        cachedValue = instance[fadeProperty]
        instance:SetAttribute(attributeName, cachedValue)
    end

    if visible then
        instance[fadeProperty] = 1
        return TweenUtil.tween(instance, tweenInfo, { [fadeProperty] = cachedValue })
    else
        instance[fadeProperty] = cachedValue
        return TweenUtil.tween(instance, tweenInfo, { [fadeProperty] = 1 })
    end
end

-- Will fade in the passed instance(s) based on an internal table of properties
function InstanceUtil.fadeIn(instanceOrInstances: Instance | { Instance }, tweenInfo: TweenInfo?)
    local tweens: { Tween } = {}

    local instances: { Instance } = typeof(instanceOrInstances) == "table" and instanceOrInstances or { instanceOrInstances }
    for _, instance in pairs(instances) do
        for fadeProperty, classNames in pairs(FADE_CLASSNAME_BY_PROPERTY) do
            for _, classname in pairs(classNames) do
                if instance:IsA(classname) then
                    table.insert(tweens, fade(instance, fadeProperty, true, tweenInfo))
                    break
                end
            end
        end
    end

    return tweens
end

-- Will fade out the passed instance(s) based on an internal table of properties
function InstanceUtil.fadeOut(instanceOrInstances: Instance | { Instance }, tweenInfo: TweenInfo?)
    local tweens: { Tween } = {}

    local instances: { Instance } = typeof(instanceOrInstances) == "table" and instanceOrInstances or { instanceOrInstances }
    for _, instance in pairs(instances) do
        for fadeProperty, classNames in pairs(FADE_CLASSNAME_BY_PROPERTY) do
            for _, classname in pairs(classNames) do
                if instance:IsA(classname) then
                    table.insert(tweens, fade(instance, fadeProperty, false, tweenInfo))
                    break
                end
            end
        end
    end

    return tweens
end

--[[
    Calls `callback` when this instance (or one of its ancestors) is destroyed. Mental we need to create a function for this..
    - Returns the Connection listening for its destruction
]]
function InstanceUtil.onDestroyed(instance: Instance, callback: () -> nil)
    local connection: RBXScriptConnection
    connection = instance.AncestryChanged:Connect(function(_, parent)
        if not parent then
            connection:Disconnect()
            callback()
        end
    end)

    return connection
end

--[[
    More mature WaitForChild implementation
]]
function InstanceUtil.waitForChild(
    instance: Instance,
    config: {
        ChildName: string?,
        ChildClassName: string?,
        Timeout: number?,
    }
)
    -- ERROR: Needs name or class
    if not (config.ChildName or config.ChildClassName) then
        error("Supply ChildName or ChildClassName")
    end

    local stopAtTick = tick() + (config.Timeout or math.huge)
    while tick() < stopAtTick do
        for _, child in pairs(instance:GetChildren()) do
            -- Both
            if
                config.ChildName
                and config.ChildClassName
                and config.ChildName == child.Name
                and config.ChildClassName == child.ClassName
            then
                return child
            end

            if config.ChildName and config.ChildName == child.Name then
                return child
            end

            if config.ChildClassName and config.ChildClassName == child.ClassName then
                return child
            end
        end
    end
end

return InstanceUtil
