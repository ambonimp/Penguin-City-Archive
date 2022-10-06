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

--[[
    Rooms and Minigames Instances must have a corresponding ZoneId
]]
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

--[[
    Convert folders to models; give us nice API (easy moving, can query extents size)
]]
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

--[[
    Appends instances with an attribute detailing how many BasePart children it has.
    Used to help the client detect when a Zone has been fully loaded
    https://create.roblox.com/docs/optimization/content-streaming#streaming-in
]]
local function writeBasePartTotals()
    -- ERROR: Models is empty (ensure we're doing *something*)
    if #models == 0 then
        error("Models is empty")
    end

    local function processInstance(instance: Instance)
        local totalBasePartChildren = 0
        for _, child in pairs(instance:GetChildren()) do
            processInstance(child)

            if child:IsA("BasePart") then
                totalBasePartChildren += 1
            end
        end

        if totalBasePartChildren > 0 then
            -- ERROR: BaseParts cannot have children that are BaseParts!
            if instance:IsA("BasePart") then
                error(
                    ("BasePart %s has children that are BaseParts - naughty! This harms content streaming"):format(instance:GetFullName())
                )
            end

            instance:SetAttribute(ZoneConstants.AttributeBasePartTotal, totalBasePartChildren)
        end
    end

    for _, model in pairs(models) do
        processInstance(model)
    end
end

--[[
    Will push a warning to the output if our streaming radius is too small for any of our zones (could risk content being streamed out)
]]
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

--[[
    Moves all our zones onto a spaced out grid to ensure we only streaming in one zone at a time
]]
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
