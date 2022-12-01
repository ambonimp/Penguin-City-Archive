local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)

local macroDefinition = {
    Name = "Write Unique Names",
    Group = "Zones",
    Icon = "❄️",
    Description = "Ensures all instances have a path (useful when :GetFullName() debugging)",
    EnableAutomaticUndo = true,
}

local function processInstance(instance: Instance)
    local totalRenames = 0

    local nameCounter: { [string]: number } = {}
    for _, child in pairs(instance:GetChildren()) do
        totalRenames += processInstance(child)

        nameCounter[child.Name] = (nameCounter[child.Name] or 0) + 1

        if nameCounter[child.Name] > 1 then
            child.Name = ("%s (%d)"):format(child.Name, nameCounter[child.Name])
            totalRenames += 1
        end
    end

    return totalRenames
end

macroDefinition.Function = function(macro, plugin)
    -- Get Selection
    local selection = Selection:Get()

    -- WARN: No selection!
    if #selection == 0 then
        Logger:MacroWarn(macro, "Select something!")
        return
    end

    local totalRenames = 0
    for _, instance in pairs(selection) do
        totalRenames += processInstance(instance)
    end

    Logger:MacroInfo(macro, ("Renamed %d instances"):format(totalRenames))
end

return macroDefinition
