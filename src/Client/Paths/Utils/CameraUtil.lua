local CameraUtil = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full height is in view
]]
function CameraUtil.getFitDepthY(fov: number, subjectSize: Vector3): number
    return (subjectSize.Y / 2) / math.tan(math.rad(fov / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full width is in view
]]
function CameraUtil.getFitDepthX(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
    local aspectRatio = viewportSize.X / viewportSize.Y

    return (subjectSize.X / 2) / math.tan(math.rad(fov * aspectRatio / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject is in view
]]
function CameraUtil.getFitDepth(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
    return math.max(CameraUtil.getFitDepthY(fov, subjectSize), CameraUtil.getFitDepthX(viewportSize, fov, subjectSize))
end

--[[
    Locks the camera and pans over to the subject
]]
function CameraUtil.lookAt(camera: Camera, subjectCFrame: CFrame, offset: CFrame, tweenInfo: TweenInfo?): (Tween, CFrame)
    CameraUtil.setCametaType(camera, Enum.CameraType.Scriptable)

    offset = offset or Vector3.new(0, 0, 10)
    tweenInfo = tweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local goal = subjectCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0) * offset.Rotation * CFrame.new(offset.Position)

    local tween = TweenUtil.tween(camera, tweenInfo, { CFrame = goal })

    return tween, goal
end

function CameraUtil.setCametaType(camera: Camera, cameraType: Enum.CameraType)
    camera.CameraType = cameraType
end

function CameraUtil.lookAtModelInViewport(viewport: ViewportFrame, model: Model, rotation: CFrame?)
    local rot = rotation or CFrame.Angles(0, 0, 0)
    local camera = viewport.CurrentCamera or Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local clone = model:Clone()
    clone.Parent = Workspace

    local size = clone:GetExtentsSize()

    clone.Parent = viewport
    local fitDepth = CameraUtil.getFitDepth(camera.ViewportSize, camera.FieldOfView, size) -- +offset
    camera.CFrame = CFrame.new(clone:GetPivot() * CFrame.new(Vector3.new(0, 0, -fitDepth)).Position, clone:GetPivot().Position)

    clone:PivotTo(model:GetPivot() * rot)
end

return CameraUtil
