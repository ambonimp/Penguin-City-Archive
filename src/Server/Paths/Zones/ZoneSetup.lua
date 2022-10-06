local ZoneSetup = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

local GRID_PADDING = 50

local rooms = game.Workspace.Rooms
local minigames = game.Workspace.Minigames

local models: { Model } = {}
local largestDiameter = 1

local function verifyDirectories()
    for _, roomFolder in pairs(rooms:GetChildren()) do
        local roomId = roomFolder.Name
        if not ZoneConstants.ZoneId.Room[roomId] then
            error(("Room Folder %s has no corresponding Room ZoneId"):format(roomFolder:GetFullName()))
        end
    end
    for _, minigameFolder in pairs(minigames:GetChildren()) do
        local minigameId = minigameFolder.Name
        if not ZoneConstants.ZoneId.Minigame[minigameId] then
            error(("Minigame Folder %s has no corresponding Minigame ZoneId"):format(minigameFolder:GetFullName()))
        end
    end
end

local function convertToModels()
    for _, directory: Instance in pairs({ rooms, minigames }) do
        for _, folder in pairs(directory:GetChildren()) do
            local model = Instance.new("Model")
            model.Name = folder.Name
            model.Parent = folder.Parent
            table.insert(models, model)

            for _, child in pairs(folder:GetChildren()) do
                child.Parent = model
            end

            folder:Destroy()
        end
    end
end

local function writeBasePartTotals()
    --todo
end

local function verifyStreamingRadius()
    -- ERROR: Models is empty (ensure we're verifying *something*)
    if #models == 0 then
        error("Models is empty")
    end

    for _, model in pairs(models) do
        local extentsSize = model:GetExtentsSize()
        local diameter = extentsSize.Magnitude
        if diameter > ZoneConstants.StreamingTargetRadius then
            warn(
                ("Zone %s has a diameter of %d; StreamingRadius (%d) should match/exceed this"):format(
                    model:GetFullName(),
                    diameter,
                    ZoneConstants.StreamingTargetRadius
                )
            )
        end

        if diameter > largestDiameter then
            largestDiameter = diameter
        end
    end

    return largestDiameter
end

local function setupGrid()
    local gridSideLength = largestDiameter + ZoneConstants.StreamingTargetRadius / 2 + GRID_PADDING

    local function moveModelToIndex(model: Model, xIndex: number, zIndex: number)
        local position = Vector3.new(gridSideLength * xIndex, 0, gridSideLength * zIndex)
        local cframe = model:GetPivot() - model:GetPivot().Position + position -- retain rotation
        model:PivotTo(cframe)
    end

    -- We loop in a spiral like this: https://i.stack.imgur.com/kjR4H.png
    for n, model in pairs(models) do
        local spiralPosition = MathUtil.getSquaredSpiralPosition(n)
        moveModelToIndex(model, spiralPosition.X, spiralPosition.Y)
    end
end

--[[
    Does a lot of setup needed to convert from developer to live.

    Runs checks to ensure we have done enough setup on the developer end.
]]
function ZoneSetup.setup()
    verifyDirectories()
    convertToModels()
    writeBasePartTotals()
    verifyStreamingRadius()
    setupGrid()
end

return ZoneSetup
