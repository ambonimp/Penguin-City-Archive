---
-- View a Camera
---

--------------------------------------------------
-- Dependencies
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")
local Utils = ServerStorage.SocketPlugin:FindFirstChild("Utils")
local Logger = require(Utils.Logger)
local CameraUtil = require(Utils.CameraUtil)

--------------------------------------------------
-- Types
-- ...

--------------------------------------------------
-- Members

local macroDefinition = {
	Name = "View Camera",
	Group = "Misc",
	Icon = "📷",
	Description = "Click a Camera model + run to view the scene through that camera",
	EnableAutomaticUndo = true,
}

macroDefinition.Function = function(macro, plugin)
	-- Get selected camera
	local cameraModel = Selection:Get()[1]
	if cameraModel then
		local lens: Part = cameraModel:FindFirstChild("Lens")
		if lens then
			CameraUtil:TeleportTo(lens.Position, lens.CFrame.LookVector)
			return
		end
	end

	Logger:MacroWarn(macro, "Please select a valid `Camera` model with a Lens part!")
end

return macroDefinition
