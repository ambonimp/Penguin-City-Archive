---
-- View a Camera
---

--------------------------------------------------
-- Dependencies
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)

--------------------------------------------------
-- Types
-- ...

--------------------------------------------------
-- Members
local camera = game.Workspace.CurrentCamera

local macroDefinition = {
    Name = "Set Camera",
    Group = "Misc",
    Icon = "📷",
    Description = "Moves the selected camera to the current camera cframe",
    EnableAutomaticUndo = true,
}

macroDefinition.Function = function(macro, plugin)
    -- Get selected camera
    local cameraModel: Model = Selection:Get()[1]
    if cameraModel then
        local lens: Part = cameraModel:FindFirstChild("Lens")
        if lens then
            -- WARN: Must be primary part
            if cameraModel.PrimaryPart ~= lens then
                Logger:MacroWarn(macro, ("`Lens` is not the PrimaryPart of %s"):format(cameraModel:GetFullName()))
                return
            end

            cameraModel:PivotTo(camera.CFrame)
            return
        end
    end

    Logger:MacroWarn(macro, "Please select a valid `Camera` model with a Lens part!")
end

return macroDefinition
