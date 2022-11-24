local Wind = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RunService = game:GetService("RunService")
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)

Wind.Defaults = {
    Direction = Vector3.new(1, 0, 0),
    Speed = 5,
    Rate = 1,
    Lifetime = 3,
    Radius = 50,
}

local currentCamera = game.Workspace.CurrentCamera

function Wind.new()
    local wind = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local stepped: RBXScriptConnection | nil
    local nextWindAtTick: number | nil

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    wind.Direction = Wind.Defaults.Direction
    wind.Speed = Wind.Defaults.Speed
    wind.Rate = Wind.Defaults.Rate
    wind.Lifetime = Wind.Defaults.Lifetime
    wind.Radius = Wind.Defaults.Radius

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function createWind()
        local position = currentCamera.CFrame.Position + VectorUtil.getUnit(VectorUtil.nextVector3(-1, 1)) * wind.Radius
        DebugUtil.flashPoint(position)
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
        stepped = RunService.RenderStepped:Connect(onRenderStepped)
    end

    function wind:Stop()
        if not stepped then
            return
        end
        stepped:Disconnect()
        stepped = nil
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
