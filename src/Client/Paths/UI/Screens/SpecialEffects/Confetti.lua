local Particles = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

type Range = {
    Min: number,
    Max: number,
}

local DEFAULT_COLORS = {
    Color3.fromRGB(168, 100, 253),
    Color3.fromRGB(41, 205, 255),
    Color3.fromRGB(120, 255, 68),
    Color3.fromRGB(255, 113, 141),
    Color3.fromRGB(253, 255, 106),
}

local DEFAULT_SIZES = {
    Vector2.new(1, 1.5),
    Vector2.new(0.5, 1.5),
    Vector2.new(1, 1),
}

local DEFAULT_LENGTH_RANGE = {
    Min = 1,
    Max = 2,
}

local DEFAULT_LAYERS = 3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()

local particleTempate: MeshPart = Paths.Templates.SpecialEffects.Confetti

local container = Instance.new("ViewportFrame")
container.BackgroundColor3 = Color3.new(1, 1, 1)
container.BackgroundTransparency = 1
container.Name = "Confetti"
container.Size = UDim2.fromScale(1, 1)
container.Parent = Paths.UI.SpecialEffects
container.Ambient = Color3.fromRGB(255, 255, 255)
container.LightColor = Color3.fromRGB(255, 255, 255)

local viewportCamera: Camera = Instance.new("Camera")
viewportCamera.Parent = container
container.CurrentCamera = viewportCamera

local fov: number = viewportCamera.FieldOfView
local origin: CFrame = viewportCamera.CFrame

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function Particles.play(count: number?, lengthRange: Range?, layers: number, colors: { Color3 }?, sizes: { Vector2 }?)
    colors = colors or DEFAULT_COLORS
    sizes = sizes or DEFAULT_SIZES
    count = count or random:NextInteger(35, 45)
    lengthRange = lengthRange or DEFAULT_LENGTH_RANGE
    layers = layers or DEFAULT_LAYERS

    local maxWidth: number = -1
    for _, size in pairs(sizes) do
        local width = size.X
        if width > maxWidth then
            maxWidth = width
        end
    end

    local deph: number = CameraUtil.getFitDephX(container.AbsoluteSize, fov, Vector3.new(maxWidth * count, 0, 0))
    local height: number = deph * math.tan(math.rad(fov / 2))

    for j = 1, layers do
        for i = 1, count do
            local size: Vector2 = sizes[random:NextInteger(1, #sizes)]
            local xOffset: number = size.X * random:NextInteger(2, 4)
            local yOffset: number = size.Y
            local displacement: number = height + yOffset

            local start = origin * CFrame.new(-(size.X / 2) + (i - (count / 2)) * size.X + xOffset, displacement, -deph)
            local goalPosition = start * CFrame.new(0, -2 * displacement, 0).Position
            local goalOrientationAddend = Vector3.new(1, 0, 1) * (random:NextInteger(0, 1) == 0 and 1 or -1) * 360

            local particle = particleTempate:Clone()
            particle.Name = i :: string
            particle.Color = colors[i % #colors + 1]
            particle.Size = Vector3.new(size.X, size.Y, 0)
            particle.CFrame = start * CFrame.Angles(math.random(1, math.pi), math.random(1, math.pi), 0)
            particle.Anchored = true
            particle.Parent = container

            local delay = (j - 1) + random:NextNumber(0, math.min(2, lengthRange.Max / 3))

            local length = random:NextNumber(lengthRange.Min, lengthRange.Max)
            local fall: Tween = TweenService:Create(
                particle,
                TweenInfo.new(length, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, delay),
                { Position = goalPosition }
            )
            local flip = TweenService:Create(
                particle,
                TweenInfo.new(length, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, true, delay),
                { Orientation = particle.Orientation + goalOrientationAddend }
            )

            fall.Completed:Connect(function()
                flip:Cancel() -- Just in case
                particle:Destroy()
            end)

            fall:Play()
            flip:Play()
        end
    end
end

return Particles
