---
-- Displays via a temporary part the look vector of the selected part(s)
---

--------------------------------------------------
-- Dependencies
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)
local InstanceUtil = require(Utils.InstanceUtil)

--------------------------------------------------
-- Types
-- ...

--------------------------------------------------
-- Constants
local FIELD_COLOR = "Color"
local DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)

local FIELD_WIDTH = "Width"
local DEFAULT_WIDTH = 0.5

local FIELD_SHOW_FOR = "Show For"
local DEFAULT_SHOW_FOR = 3

local FIELD_MIN_LENGTH = "Min Length"
local DEFAULT_MIN_LENGTH = 5

--------------------------------------------------
-- Members

local macroDefinition = {
    Name = "Show Look Vector",
    Group = "Misc",
    Icon = "↗️",
    Description = "Shows the look vector of the selected part(s)",
    EnableAutomaticUndo = false,
    Fields = {
        {
            Name = FIELD_COLOR,
            Type = "Color3",
            IsRequired = true,
        },
        {
            Name = FIELD_WIDTH,
            Type = "number",
            IsRequired = true,
        },
        {
            Name = FIELD_SHOW_FOR,
            Type = "number",
            IsRequired = true,
        },
        {
            Name = FIELD_MIN_LENGTH,
            Type = "number",
            IsRequired = true,
        },
    },
    State = {
        FieldValues = {
            [FIELD_COLOR] = DEFAULT_COLOR,
            [FIELD_WIDTH] = DEFAULT_WIDTH,
            [FIELD_SHOW_FOR] = DEFAULT_SHOW_FOR,
            [FIELD_MIN_LENGTH] = DEFAULT_MIN_LENGTH,
        },
    },
}

macroDefinition.Function = function(macro, plugin)
    -- Get Parts
    local parts: { BasePart } = {}
    for _, instance in pairs(Selection:Get()) do
        if instance:IsA("BasePart") then
            table.insert(parts, instance)
        end
    end

    if #parts == 0 then
        Logger:MacroWarn(macro, "Please select atleast 1 part")
        return
    end

    -- Read fields
    local color = macro:GetFieldValue(FIELD_COLOR)
    local width = macro:GetFieldValue(FIELD_WIDTH)
    local showFor = macro:GetFieldValue(FIELD_SHOW_FOR)
    local minLength = macro:GetFieldValue(FIELD_MIN_LENGTH)

    -- Display
    local lookVectorParts: { BasePart } = {}
    for _, part in pairs(parts) do
        local len = math.max(part.Size.Z, minLength)

        -- Create look vector part
        local lookVectorPart = Instance.new("Part")
        lookVectorPart.Color = color
        lookVectorPart.Size = Vector3.new(width, width, len)

        local position = part.Position + part.CFrame.LookVector * (len / 2)
        lookVectorPart.CFrame = CFrame.new(position, position + part.CFrame.LookVector)

        InstanceUtil:IntroduceInstance(lookVectorPart, true)
        table.insert(lookVectorParts, lookVectorPart)
    end

    -- Later, remove..
    task.spawn(function()
        task.wait(showFor)
        for _, lookVectorPart in pairs(lookVectorParts) do
            InstanceUtil:ClearInstance(lookVectorPart, true)
        end
    end)
end

return macroDefinition
