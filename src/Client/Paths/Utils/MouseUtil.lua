local MouseUtil = {}

local UserInputService = game:GetService("UserInputService")

local camera = workspace.CurrentCamera

function MouseUtil.getMouseTarget(ignore: { Instance }, ignoresWater: boolean): RaycastResult | nil
    local cursorPosition = UserInputService:GetMouseLocation()

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignore or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = ignoresWater

    local CameraRay = workspace.CurrentCamera:ViewportPointToRay(cursorPosition.X, cursorPosition.Y, 0)

    local raycastResult = workspace:Raycast(camera.CFrame.Position, CameraRay.Direction * 50, raycastParams)

    if raycastResult then
        return raycastResult
    else
        return nil
    end
end

return MouseUtil
