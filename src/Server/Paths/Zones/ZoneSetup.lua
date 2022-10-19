local ZoneSetup = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

local GRID_PADDING = 128
local GRID_RAISE_EVERY = 100 -- 10x10

local rooms = game.Workspace.Rooms
local minigames = game.Workspace.Minigames

local staticModels: { Model } = {}
local largestDiameter = 1
local gridSideLength = 1
local usedGridIndexes: { [number]: boolean } = {}

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
    Convert folders to staticModels; give us nice API (easy moving, can query extents size)
]]
local function convertToModels()
    for _, directory: Instance in pairs({ rooms, minigames }) do
        for _, folder in pairs(directory:GetChildren()) do
            local model = Instance.new("Model")
            model.Name = folder.Name
            model.Parent = folder.Parent
            table.insert(staticModels, model)

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
    Ensures staticModels all have the required pre-requisites
]]
local function verifyAndCleanModels(someModels: { Model })
    local function verifyModel(model: Model)
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
        local zoneType = model.Parent == game.Workspace.Rooms and ZoneConstants.ZoneType.Room
            or model.Parent == game.Workspace.Minigames and ZoneConstants.ZoneType.Minigame
            or error(("Could not infer ZoneType from %q"):format(model:GetFullName()))

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

    for _, model in pairs(someModels) do
        verifyModel(model)
    end
end

local function readWriteBasePartTotals(instance: Instance)
    local totalBasePartChildren = 0
    for _, child in pairs(instance:GetChildren()) do
        if child:IsA("BasePart") then
            totalBasePartChildren += 1
        end
    end

    if totalBasePartChildren > 0 then
        instance:SetAttribute(ZoneConstants.AttributeBasePartTotal, totalBasePartChildren)
    else
        instance:SetAttribute(ZoneConstants.AttributeBasePartTotal, nil)
    end
end

local function processInstanceBasePartTotals(instance: Instance)
    -- RETURN: Already processed
    if instance:GetAttribute(ZoneConstants.AttributeIsProcessed) then
        return
    end
    instance:SetAttribute(ZoneConstants.AttributeIsProcessed, true)

    readWriteBasePartTotals(instance)

    -- Children added/removed
    instance.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") then
            readWriteBasePartTotals(instance)
        end
    end)
    instance.ChildRemoved:Connect(function(child)
        if child:IsA("BasePart") then
            readWriteBasePartTotals(instance)
        end
    end)

    -- Children
    for _, child in pairs(instance:GetChildren()) do
        processInstanceBasePartTotals(child)
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

--[[
    Appends instances with an attribute detailing how many BasePart children it has.
    Used to help the client detect when a Zone has been fully loaded
    https://create.roblox.com/docs/optimization/content-streaming#streaming-in
]]
local function writeBasePartTotals(writeModels: { Model })
    -- ERROR: Models is empty (ensure we're doing *something*)
    if #staticModels == 0 then
        error("Models is empty")
    end

    for _, model in pairs(writeModels) do
        -- Now
        processInstanceBasePartTotals(model)

        -- Future adds/removals
        model.DescendantAdded:Connect(function(descendant: Instance)
            processInstanceBasePartTotals(descendant)
        end)
        model.DescendantRemoving:Connect(function(descendant: Instance)
            if descendant:IsA("BasePart") and descendant.Parent then
                readWriteBasePartTotals(descendant.Parent)
            end
        end)
    end
end

--[[
    Will push a warning to the output if our streaming radius is too small for any of our zones (could risk content being streamed out)
]]
local function verifyStreamingRadius()
    -- ERROR: Models is empty (ensure we're verifying *something*)
    if #staticModels == 0 then
        error("Models is empty")
    end

    for _, model in pairs(staticModels) do
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

local function placeModelOnGrid(model: Model)
    -- Find next available index
    local index = 1
    while usedGridIndexes[index] do
        index += 1
    end
    usedGridIndexes[index] = true

    -- Convert into horizontal and vertical components
    local horizontal = MathUtil.wrapAround(index, GRID_RAISE_EVERY)
    local vertical = math.floor((index - 1) / GRID_RAISE_EVERY)

    -- We loop in a spiral like this: https://i.stack.imgur.com/kjR4H.png
    local spiralPosition = MathUtil.getSquaredSpiralPosition(horizontal)

    local position = Vector3.new(gridSideLength * spiralPosition.X, gridSideLength * vertical, gridSideLength * spiralPosition.Y)
    local cframe = model:GetPivot() - model:GetPivot().Position + position -- retain rotation
    model:PivotTo(cframe)

    -- Listen for release index
    model.Destroying:Connect(function()
        usedGridIndexes[index] = nil
    end)
end

--[[
    Moves all our zones onto a spaced out grid to ensure we only streaming in one zone at a time
]]
local function setupGrid()
    gridSideLength = largestDiameter + ZoneConstants.StreamingTargetRadius + GRID_PADDING

    -- We loop in a spiral like this: https://i.stack.imgur.com/kjR4H.png
    for _, model in pairs(staticModels) do
        placeModelOnGrid(model)
    end
end

-------------------------------------------------------------------------------
--  API
-------------------------------------------------------------------------------

function ZoneSetup.setupCreatedZone(zoneModel: Model)
    verifyAndCleanModels({ zoneModel })
    writeBasePartTotals({ zoneModel })
    placeModelOnGrid(zoneModel)
end

--[[
    Does a lot of setup needed to convert from developer to live.

    Runs checks to ensure we have done enough setup on the developer end.
]]
function ZoneSetup.setup()
    verifyDirectories()
    convertToModels()
    verifyAndCleanModels(staticModels)
    writeBasePartTotals(staticModels)
    verifyStreamingRadius()
    setupGrid()
end

return ZoneSetup
