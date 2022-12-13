local InstanceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
local PropertyStack = require(ReplicatedStorage.Shared.PropertyStack)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

local FADE_CLASSNAME_BY_PROPERTY = {
    Transparency = { "BasePart", "UIStroke", "Decal", "Texture" },
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

function InstanceUtil.hide(instanceOrInstances: Instance | { Instance }, tweenInfo: TweenInfo?)
    local instances: { Instance } = typeof(instanceOrInstances) == "table" and instanceOrInstances or { instanceOrInstances }

    for fadeProperty, classNames in pairs(FADE_CLASSNAME_BY_PROPERTY) do
        for _, classname in pairs(classNames) do
            for _, instance in pairs(instances) do
                if instance:IsA(classname) then
                    if tweenInfo then
                        local defaultValue = PropertyStack.getDefaultValue(instance, fadeProperty)
                        TweenUtil.run(function(alpha)
                            local alphaValue = MathUtil.lerp(defaultValue, 1, alpha)
                            PropertyStack.setProperty(instance, fadeProperty, alphaValue, "InstanceUtilHide")
                        end, tweenInfo)
                    else
                        PropertyStack.setProperty(instance, fadeProperty, 1, "InstanceUtilHide")
                    end

                    break
                end
            end
        end
    end
end

function InstanceUtil.show(instanceOrInstances: Instance | { Instance }, tweenInfo: TweenInfo?)
    local instances: { Instance } = typeof(instanceOrInstances) == "table" and instanceOrInstances or { instanceOrInstances }

    for fadeProperty, classNames in pairs(FADE_CLASSNAME_BY_PROPERTY) do
        for _, classname in pairs(classNames) do
            for _, instance in pairs(instances) do
                if instance:IsA(classname) then
                    if tweenInfo then
                        local defaultValue = PropertyStack.getDefaultValue(instance, fadeProperty)
                        TweenUtil.run(function(alpha)
                            local alphaValue = MathUtil.lerp(1, defaultValue, alpha)
                            if alphaValue < 1 then
                                PropertyStack.setProperty(instance, fadeProperty, alphaValue, "InstanceUtilHide")
                            else
                                PropertyStack.clearProperty(instance, fadeProperty, "InstanceUtilHide")
                            end
                        end, tweenInfo)
                    else
                        PropertyStack.clearProperty(instance, fadeProperty, "InstanceUtilHide")
                    end

                    break
                end
            end
        end
    end
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

local function doesChildHaveNameAndOrClassName(child: Instance, childName: string?, childClassName: string?)
    local hasChildName = child.Name == childName
    local hasChildClassName = child.ClassName == childClassName

    -- If passed both, both must match
    if childName and childClassName then
        return hasChildName and hasChildClassName and true or false
    end

    return hasChildName or hasChildClassName and true or false
end

--[[
    More mature FindFirstChild implementation.

    - Can pass both `ChildName` and `ChildClassName`, must match both
    - `Recurse` declares whether to look for children or descendants
]]
function InstanceUtil.findFirstChild(
    instance: Instance,
    config: {
        ChildName: string?,
        ChildClassName: string?,
        Recurse: boolean?,
    }
)
    -- ERROR: Needs name or class
    if not (config.ChildName or config.ChildClassName) then
        error("Supply ChildName or ChildClassName")
    end

    local instancesToCheck = config.Recurse and instance:GetDescendants() or instance:GetChildren()
    for _, child in pairs(instancesToCheck) do
        print(
            config.ChildName,
            "=",
            child.Name,
            "  ",
            config.ChildClassName,
            "=",
            child.ClassName,
            "  ",
            doesChildHaveNameAndOrClassName(child, config.ChildName, config.ChildClassName)
        )
        if doesChildHaveNameAndOrClassName(child, config.ChildName, config.ChildClassName) then
            return child
        end
    end

    return nil
end

--[[
    Ditto to `InstanceUtil.findFirstChild`, but returns an array of children that matched the search
]]
function InstanceUtil.findChildren(
    instance: Instance,
    config: {
        ChildName: string?,
        ChildClassName: string?,
        Recurse: boolean?,
    }
)
    -- ERROR: Needs name or class
    if not (config.ChildName or config.ChildClassName) then
        error("Supply ChildName or ChildClassName")
    end

    local instancesToCheck = config.Recurse and instance:GetDescendants() or instance:GetChildren()
    local results: { Instance } = {}
    for _, child in pairs(instancesToCheck) do
        if doesChildHaveNameAndOrClassName(child, config.ChildName, config.ChildClassName) then
            table.insert(results, child)
        end
    end

    return results
end

--[[
    More mature WaitForChild implementation.

    - Can pass both `ChildName` and `ChildClassName`, must match both
    - `Timeout` is an exercise left to the reader
    - `Recurse` declares whether to look for children or descendants
]]
function InstanceUtil.waitForChild(
    instance: Instance,
    config: {
        ChildName: string?,
        ChildClassName: string?,
        Timeout: number?,
        Recurse: boolean?,
    }
)
    -- ERROR: Needs name or class
    if not (config.ChildName or config.ChildClassName) then
        error("Supply ChildName or ChildClassName")
    end

    local stopAtTick = tick() + (config.Timeout or math.huge)

    local findFirstChildConfig = {
        ChildName = config.ChildName,
        ChildClassName = config.ChildClassName,
        Recurse = config.Recurse,
    }
    while tick() < stopAtTick do
        local result = InstanceUtil.findFirstChild(instance, findFirstChildConfig)
        if result then
            return result
        end
    end
end

return InstanceUtil
