local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)

local function weldBaseParts(baseParts: { BasePart })
    for i = 1, #baseParts - 1 do
        local part0 = baseParts[i]
        local part1 = baseParts[i + 1]

        local weldConstraint = Instance.new("WeldConstraint")
        weldConstraint.Name = ("%s_weld_%s"):format(part0.Name, part1.Name)
        weldConstraint.Part0 = part0
        weldConstraint.Part1 = part1
        weldConstraint.Parent = baseParts[1]
    end

    return math.max(#baseParts - 1, 0)
end

local function weldModel(model: Model)
    local baseParts: { BasePart } = {}
    for _, instance in pairs(model:GetDescendants()) do
        if instance:IsA("BasePart") then
            table.insert(baseParts, instance)
        end
    end
    return weldBaseParts(baseParts)
end

return {
    Name = "Weld",
    Group = "Misc",
    Icon = "🔗",
    Description = "Welds all selected BaseParts together. You can also select a Model, and it will weld the whole model together",
    EnableAutomaticUndo = true,
    Function = function(macro, _plugin)
        local selection = Selection:Get()

        local baseParts: { BasePart } = {}
        local totalWelds = 0
        for _, instance in pairs(selection) do
            if instance:IsA("Model") then
                -- EDGE CASE: Weld whole model together
                totalWelds += weldModel(instance)
                Logger:MacroInfo(macro, ("Welded Model %s"):format(instance:GetFullName()))
            elseif instance:IsA("BasePart") then
                table.insert(baseParts, instance)
            end
        end

        totalWelds += weldBaseParts(baseParts)

        Logger:MacroInfo(macro, ("Created %d welds"):format(totalWelds))
    end,
}
