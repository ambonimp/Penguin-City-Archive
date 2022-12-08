local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)

local THROTTLE_EVERY = 1000

local macroDefinition = {
    Name = "Fix Rendering Fidelity",
    Group = "Performance",
    Icon = "⛰️",
    Description = "Sets the rendering fidelity of ALL parts to be as performatic as possible",
    EnableAutomaticUndo = false,
    Function = function(macro, _plugin)
        -- WARN: No selection!
        local selection = Selection:Get()
        if #selection == 0 then
            Logger:MacroWarn(macro, "No selection!")
            return
        end

        local totalUpdates = 0
        for _, selectionInstance in pairs(selection) do
            -- Get Instances
            local instances = selectionInstance:GetDescendants()
            table.insert(instances, selectionInstance)

            -- Iterate
            for i, instance: MeshPart in pairs(instances) do
                -- Throttle
                if i % THROTTLE_EVERY == 0 then
                    task.wait()
                end

                if instance:IsA("MeshPart") and instance.RenderFidelity ~= Enum.RenderFidelity.Performance then
                    totalUpdates += 1
                    instance.RenderFidelity = Enum.RenderFidelity.Performance
                end
            end
        end

        ChangeHistoryService:SetWaypoint("FixRenderFidelity")
        Logger:MacroInfo(macro, ("Updated %d MeshParts"):format(totalUpdates))
    end,
}

return macroDefinition
