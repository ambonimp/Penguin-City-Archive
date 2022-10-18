local ZoneSetup = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

local GRID_PADDING = 128

local rooms = game.Workspace.Rooms
local minigames = game.Workspace.Minigames

local models: { Model } = {}
local largestDiameter = 1
local gridSideLength = 1

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

            -- Delete package link
            local packageLink = folder:FindFirstChildWhichIsA("PackageLink")
            if packageLink then
                packageLink:Destroy()
            end

            -- Reparent
            for _, child in pairs(folder:GetChildren()) do
                child.Parent = model
            end

            folder:Destroy()
        end
    end
end

--[[
    Ensures models all have the required pre-requisites
]]
local function verifyAndCleanModels()
    local function verifyModel(zoneType: string, model: Model)
        local zoneId = model.Name

        -- WARN: No ZoneInstances!
        local zoneInstancesInstance = model:FindFirstChild("ZoneInstances")
        if not zoneInstancesInstance then
            warn(("ZoneModel %s missing 'ZoneInstances'"):format(model:GetFullName()))
            return
        end

        -- Clean instances
        for _, instance in pairs(zoneInstancesInstance:GetDescendants()) do
            if instance:IsA("BasePart") then
                -- WARN: Not anchored
                if not instance.Anchored then
                    warn(("ZoneInstance %s is not anchored!"):format(instance:GetFullName()))
                end

                instance.Transparency = 1
                instance.CanCollide = false
            end
        end

        -- WARN: Needs spawnpoint!
        local zoneInstances = ZoneUtil.getZoneInstances(ZoneUtil.zone(zoneType, zoneId))
        if not (zoneInstances.Spawnpoint and zoneInstances.Spawnpoint:IsA("BasePart")) then
            warn(("ZoneModel %s missing 'ZoneInstances.Spawnpoint (BasePart)'"):format(model:GetFullName()))
        end

        -- Verify arrivals/departures
        for _, someZoneType in pairs(ZoneConstants.ZoneType) do
            for _, direction in pairs({ "Arrivals", "Departures" }) do
                local folder = zoneInstances[("%s%s"):format(someZoneType, direction)]
                if folder then
                    for _, child in pairs(folder:GetChildren()) do
                        -- ERROR: Not a base part
                        if not child:IsA("BasePart") then
                            warn(("%s should only contains parts! (%s)"):format(folder:GetFullName(), child:GetFullName()))
                        end

                        -- ERROR: Bad zoneid
                        local someZoneId = child.Name
                        local isGoodId = ZoneConstants.ZoneId[someZoneType][someZoneId] and true or false
                        if not isGoodId then
                            warn(("%s does not match any known %s Id!"):format(child:GetFullName(), someZoneType))
                        end
                    end
                end
            end
        end
    end

    for _, model in pairs(rooms:GetChildren()) do
        verifyModel(ZoneConstants.ZoneType.Room, model)
    end
    for _, model in pairs(minigames:GetChildren()) do
        verifyModel(ZoneConstants.ZoneType.Minigame, model)
    end
end

--[[
    Appends instances with an attribute detailing how many BasePart children it has.
    Used to help the client detect when a Zone has been fully loaded
    https://create.roblox.com/docs/optimization/content-streaming#streaming-in
]]
local function writeBasePartTotals(writeModels: { Model })
    -- ERROR: Models is empty (ensure we're doing *something*)
    if #models == 0 then
        error("Models is empty")
    end

    local function processInstance(instance: Instance)
        -- Children
        local totalBasePartChildren = 0
        for _, child in pairs(instance:GetChildren()) do
            processInstance(child)

            if child:IsA("BasePart") then
                totalBasePartChildren += 1
            end
        end
        if totalBasePartChildren > 0 then
            instance:SetAttribute(ZoneConstants.AttributeBasePartTotal, totalBasePartChildren)
        end

        -- Descendants
        local totalBasePartDescendants = 0
        for _, descendant in pairs(instance:GetDescendants()) do
            if descendant:IsA("BasePart") then
                totalBasePartDescendants += 1
            end
        end
        if totalBasePartDescendants > 0 then
            -- ERROR: BaseParts cannot have descendants that are BaseParts!
            if instance:IsA("BasePart") then
                error(
                    ("BasePart %s has descendants that are BaseParts - naughty! This harms content streaming. Use the 'Fix Nested BaseParts' macro (Socekt)"):format(
                        instance:GetFullName()
                    )
                )
            end
        end
    end

    for _, model in pairs(writeModels) do
        -- Now
        processInstance(model)

        -- Future
        model.DescendantAdded:Connect(function(descendant: Instance)
            if descendant:IsA("BasePart") and descendant.Parent then
                local parentTotal = descendant.Parent:GetAttribute(ZoneConstants.AttributeBasePartTotal) or 0
                descendant.Parent:SetAttribute(ZoneConstants.AttributeBasePartTotal, parentTotal + 1)
            end
        end)
        model.DescendantRemoving:Connect(function(descendant: Instance)
            if descendant:IsA("BasePart") and descendant.Parent then
                local parentTotal = descendant.Parent:GetAttribute(ZoneConstants.AttributeBasePartTotal) or 0
                descendant.Parent:SetAttribute(ZoneConstants.AttributeBasePartTotal, math.max(parentTotal - 1, 0))
            end
        end)
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
    gridSideLength = largestDiameter + ZoneConstants.StreamingTargetRadius + GRID_PADDING

    -- We loop in a spiral like this: https://i.stack.imgur.com/kjR4H.png
    for n, model in pairs(models) do
        ZoneSetup.placeModelOnGrid(model, n, ZoneConstants.GridPriority.RoomsAndMinigames)
    end
end

-------------------------------------------------------------------------------
--  API
-------------------------------------------------------------------------------

function ZoneSetup.placeModelOnGrid(model: Model, horizontalIndex: number, yIndex: number)
    -- We loop in a spiral like this: https://i.stack.imgur.com/kjR4H.png
    local spiralPosition = MathUtil.getSquaredSpiralPosition(horizontalIndex)

    local position = Vector3.new(gridSideLength * spiralPosition.X, gridSideLength * yIndex, gridSideLength * spiralPosition.Y)
    local cframe = model:GetPivot() - model:GetPivot().Position + position -- retain rotation
    model:PivotTo(cframe)
end

function ZoneSetup.setupIglooRoom(room: Model)
    writeBasePartTotals({ room })
end

--[[
    Does a lot of setup needed to convert from developer to live.

    Runs checks to ensure we have done enough setup on the developer end.
]]
function ZoneSetup.setup()
    verifyDirectories()
    convertToModels()
    verifyAndCleanModels()
    writeBasePartTotals(models)
    verifyStreamingRadius()
    setupGrid()
end

return ZoneSetup
