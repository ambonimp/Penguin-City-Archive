local CameraUtil = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full height is in view
]]
function CameraUtil.getFitDephY(fov: number, subjectSize: Vector3): number
    return (subjectSize.Y / 2) / math.tan(math.rad(fov / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full width is in view
]]
function CameraUtil.getFitDephX(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
    local aspectRatio = viewportSize.X / viewportSize.Y

    return (subjectSize.X / 2) / math.tan(math.rad(fov * aspectRatio / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject is in view
]]
function CameraUtil.getFitDeph(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
    return math.max(CameraUtil.getFitDephY(fov, subjectSize), CameraUtil.getFitDephX(viewportSize, fov, subjectSize))
end

--[[
    Locks the camera and pans over to the subject
]]
function CameraUtil.lookAt(camera: Camera, subject: BasePart | Model, offset: Vector3, tweenInfo: TweenInfo?): (Tween, CFrame)
    camera.CameraType = Enum.CameraType.Scriptable

    offset = offset or Vector3.new(0, 0, 10)
    tweenInfo = tweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local subjectCFrame: CFrame = if subject:IsA("Model") then subject:GetBoundingBox() else subject.CFrame
    local goal = subjectCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0) * CFrame.new(offset)

    local tween = TweenUtil.tween(camera, tweenInfo, { CFrame = goal })

    return tween, goal
end

return CameraUtil