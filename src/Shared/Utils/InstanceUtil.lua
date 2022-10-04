local InstanceUtil = {}

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
    for property, value in props do
        instance[property] = value
    end

    if children then
        for _, child in children do
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

function InstanceUtil.weld(mainPart: BasePart, otherPart: BasePart)
    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Name = otherPart:GetFullName()
    weldConstraint.Part0 = mainPart
    weldConstraint.Part1 = otherPart
    weldConstraint.Parent = mainPart

    return weldConstraint
end

function InstanceUtil.findFirstDescendant(instance: Instance, searchingFor: string): Instance?
    for _, descendant in instance:GetDescendants() do
        if descendant.Name == searchingFor then
            return descendant
        end
    end
end

return InstanceUtil
