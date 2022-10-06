local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)

local macroDefinition = {
    Name = "Fix Nested BaseParts",
    Group = "Zones",
    Icon = "♻️",
    Description = "Zones can not have BaseParts nested inside BaseParts; this fixes that!",
    EnableAutomaticUndo = true,
}

local function processInstance(instance: Instance)
    local totalFixes = 0
    local isBasePart = instance:IsA("BasePart")
    local fixModel: Model
    for _, child in pairs(instance:GetChildren()) do
        -- Fix!
        if child:IsA("BasePart") and isBasePart then
            if not fixModel then
                fixModel = Instance.new("Model")
                fixModel.Name = instance.Name
                fixModel.Parent = instance.Parent
            end

            totalFixes += 1
            child.Parent = fixModel
        end

        totalFixes += processInstance(child)
    end

    return totalFixes
end

macroDefinition.Function = function(macro, plugin)
    -- Get Selection
    local selection = Selection:Get()

    -- WARN: No selection!
    if #selection == 0 then
        Logger:MacroWarn(macro, "Select something!")
        return
    end

    local totalFixes = 0
    for _, instance in pairs(selection) do
        totalFixes += processInstance(instance)
    end

    Logger:MacroInfo(macro, ("Fixed %d total nested BaseParts!"):format(totalFixes))
end

return macroDefinition
