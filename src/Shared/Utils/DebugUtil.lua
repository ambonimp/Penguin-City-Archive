local DebugUtil = {}

local RAYCAST_DURATION = 2
local FLASH_POINT_DURATION = 1

local function getDebugPart()
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Name = "DebugPart"
    part.Transparency = 0.5
    part.Size = Vector3.new(1, 1, 1)
    part.Shape = Enum.PartType.Ball
    part.Parent = game.Workspace

    return part
end

function DebugUtil.showRaycast(origin: Vector3, direction: Vector3, length: number, raycastResult: RaycastResult?)
    local startPart = getDebugPart()
    startPart.Shape = Enum.PartType.Ball
    startPart.Size = Vector3.new(0.3, 0, 0.3)
    startPart.Color = Color3.fromRGB(0, 255, 0)
    startPart.Position = origin

    local rayPart = getDebugPart()
    rayPart.Size = Vector3.new(0.1, 0.1, length)
    rayPart.CFrame = CFrame.lookAt(origin + direction, origin) * CFrame.new(0, 0, -length / 2)
    rayPart.Color = Color3.fromRGB(255, 166, 0)

    local endPart = getDebugPart()
    endPart.Shape = Enum.PartType.Ball
    endPart.Size = Vector3.new(0.3, 0, 0.3)
    endPart.Color = Color3.fromRGB(255, 0, 0)
    endPart.Position = origin + direction.Unit * length

    if raycastResult then
        local hitPart = getDebugPart()
        hitPart.Shape = Enum.PartType.Ball
        hitPart.Size = Vector3.new(0.2, 0.2, 0.2)
        hitPart.Color = Color3.fromRGB(0, 38, 255)
        hitPart.Transparency = 0
        hitPart.Position = raycastResult.Position

        task.delay(RAYCAST_DURATION, function()
            hitPart:Destroy()
        end)
    end

    task.delay(RAYCAST_DURATION, function()
        startPart:Destroy()
        rayPart:Destroy()
        endPart:Destroy()
    end)
end

function DebugUtil.flashPoint(position: Vector3, color: Color3?)
    local part = getDebugPart()
    part.Color = color or Color3.fromRGB(255, 0, 0)
    part.Position = position

    task.delay(FLASH_POINT_DURATION, function()
        part:Destroy()
    end)
end

return DebugUtil
