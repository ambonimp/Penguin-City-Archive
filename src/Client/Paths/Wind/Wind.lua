local Wind = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RunService = game:GetService("RunService")
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local CFrameUtil = require(Paths.Shared.Utils.CFrameUtil)

Wind.Defaults = {
    Direction = Vector3.new(1, 0, 0),
    Speed = 5,
    Rate = 20,
    Lifetime = 4,
    Radius = 50,
    SineFrequency = 0.1,
    SineAmplitude = 0.3,
    FadeDuration = 1,
}

local currentCamera = game.Workspace.CurrentCamera

function Wind.new()
    local wind = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local stepped: RBXScriptConnection | nil
    local nextWindAtTick: number | nil
    local windPartsFolder: Folder | nil

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    wind.Direction = Wind.Defaults.Direction
    wind.Speed = Wind.Defaults.Speed
    wind.Rate = Wind.Defaults.Rate
    wind.Lifetime = Wind.Defaults.Lifetime
    wind.Radius = Wind.Defaults.Radius
    wind.SineFrequency = Wind.Defaults.SineFrequency
    wind.SineAmplitude = Wind.Defaults.SineAmplitude
    wind.FadeDuration = Wind.Defaults.FadeDuration

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function calculateSineWave(x: number)
        return wind.SineAmplitude * math.sin((x / wind.SineFrequency))
    end

    local function fadeAndDestroyWind(windPart: Part)
        local trail: Trail = windPart:FindFirstChild("Trail")

        -- RETURN: Proably teleported out of zone with trails
        if not trail then
            return
        end

        -- Fade
        TweenUtil.run(function(alpha)
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.3, alpha),
                NumberSequenceKeypoint.new(0.6, alpha),
                NumberSequenceKeypoint.new(1, 1),
            })
        end, TweenInfo.new(wind.FadeDuration, Enum.EasingStyle.Linear))

        -- Destroy
        task.delay(wind.FadeDuration, function()
            trail.Enabled = false
            task.wait(trail.Lifetime)
            windPart:Destroy()
        end)
    end

    local function createWind()
        local startPosition = currentCamera.CFrame.Position
            + currentCamera.CFrame.LookVector.Unit * wind.Radius
            + VectorUtil.getUnit(VectorUtil.nextVector3(-1, 1)) * wind.Radius

        local windPart: Part = game.ReplicatedStorage.Assets.Misc.WindPart:Clone()
        windPart.Position = startPosition
        windPart.Parent = windPartsFolder

        -- Move in a Wave
        TweenUtil.run(function(alpha)
            local position = startPosition + wind.Direction.Unit * wind.Speed * wind.Lifetime * alpha
            windPart:PivotTo(CFrameUtil.setPosition(windPart:GetPivot(), position) * CFrame.new(0, 0, calculateSineWave(alpha)))
        end, TweenInfo.new(wind.Lifetime + wind.FadeDuration, Enum.EasingStyle.Linear))

        -- Fade
        task.delay(wind.Lifetime, fadeAndDestroyWind, windPart)
    end

    local function onRenderStepped(_dt: number)
        local createWindEvery = 1 / wind.Rate

        -- EDGE CASE: First call
        if not nextWindAtTick then
            createWind()
            nextWindAtTick = tick() + createWindEvery
            return
        end

        -- Create winds needed over the last frame
        local totalWindsToCreate = math.clamp(math.floor((tick() - nextWindAtTick) / createWindEvery), 0, math.huge)
        if totalWindsToCreate > 0 then
            for _ = 1, totalWindsToCreate do
                createWind()
            end
            nextWindAtTick = nextWindAtTick + totalWindsToCreate * createWindEvery
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function wind:Start()
        if stepped then
            return
        end

        windPartsFolder = Instance.new("Folder")
        windPartsFolder.Name = "WindPartsFolder"
        windPartsFolder.Parent = game.Workspace

        stepped = RunService.RenderStepped:Connect(onRenderStepped)
    end

    function wind:Stop()
        if not stepped then
            return
        end
        stepped:Disconnect()
        stepped = nil
        windPartsFolder:Destroy()
        windPartsFolder = nil
        nextWindAtTick = nil
    end

    function wind:Destroy()
        wind:Stop()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    --todo

    return wind
end

return Wind
