---
-- Creates a Hitbox for the passed model
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

--------------------------------------------------
-- Members

local macroDefinition = {
    Name = "Create Model Hitbox",
    Group = "Misc",
    Icon = "🗳️",
    Description = "Creates a hitbox of the selected model(s) from BoundingBox",
    EnableAutomaticUndo = true,
    Fields = {
        {
            Name = "PrimaryPart",
            Type = "boolean",
            IsRequired = true,
        },
    },
    State = {
        FieldValues = {
            PrimaryPart = true,
        },
    },
}

local function createHitboxPart()
    local hitboxPart = Instance.new("Part")
    hitboxPart.CanCollide = false
    hitboxPart.Color = Color3.fromRGB(255, 0, 0)
    hitboxPart.Transparency = 0.5
    hitboxPart.Name = "Hitbox"

    return hitboxPart
end

macroDefinition.Function = function(macro, _plugin)
    -- Read State
    local setPrimaryPart = macro:GetFieldValue("PrimaryPart")

    -- Get Models
    local models: { Model } = {}
    for _, instance in pairs(Selection:Get()) do
        if instance:IsA("Model") then
            table.insert(models, instance)
        end
    end

    -- Create Hitboxes
    for _, model in pairs(models) do
        local hitboxPart = createHitboxPart()
        local cframe, size = model:GetBoundingBox()
        hitboxPart.CFrame = cframe
        hitboxPart.Size = size
        hitboxPart.Parent = model

        if setPrimaryPart then
            model.PrimaryPart = hitboxPart
        end
    end
end

return macroDefinition
