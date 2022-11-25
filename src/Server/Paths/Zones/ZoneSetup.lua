local ZoneSetup = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local PlayersHitbox = require(Paths.Shared.PlayersHitbox)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)

local GRID_PADDING = 128
local GRID_RAISE_EVERY = 100 -- 10x10
local DEPARTURE_COLLISION_AREA_SIZE = Vector3.new(10, 2, 10)
local ETHEREAL_KEY_DEPARTURES = "ZoneService_Departure"

local rooms = game.Workspace.Rooms
local minigames = game.Workspace.Minigames

local staticModels: { Model } = {}
local largestDiameter = 1
local gridSideLength = 1
local usedGridIndexes: { [number]: boolean } = {}
local collisionDisablers: Folder

--[[
    Rooms and Minigames Instances must have a corresponding ZoneType
]]
local function verifyDirectories()
    for _, roomFolder in pairs(rooms:GetChildren()) do
        local roomId = roomFolder.Name
        if not ZoneConstants.ZoneType.Room[roomId] then
            error(("Room Folder %s has no corresponding Room ZoneType"):format(roomFolder:GetFullName()))
        end
    end
    for _, minigameFolder in pairs(minigames:GetChildren()) do
        local minigameId = minigameFolder.Name
        if not ZoneConstants.ZoneType.Minigame[minigameId] then
            error(("Minigame Folder %s has no corresponding Minigame ZoneType"):format(minigameFolder:GetFullName()))
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
        local zone = ZoneUtil.getZoneFromZoneModel(model)

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
        local zoneInstances = ZoneUtil.getZoneInstances(zone)
        if not (zoneInstances.Spawnpoint and zoneInstances.Spawnpoint:IsA("BasePart")) then
            warn(("ZoneModel %s missing 'ZoneInstances.Spawnpoint (BasePart)'"):format(model:GetFullName()))
        end

        -- Verify arrivals/departures
        for _, someZoneCategory in pairs(ZoneConstants.ZoneCategory) do
            for _, direction in pairs({ "Arrivals", "Departures" }) do
                local folder = zoneInstances[("%s%s"):format(someZoneCategory, direction)]
                if folder then
                    for _, child in pairs(folder:GetChildren()) do
                        -- ERROR: Not a base part
                        if not child:IsA("BasePart") then
                            warn(("%s should only contains parts! (%s)"):format(folder:GetFullName(), child:GetFullName()))
                        end

                        -- ERROR: Bad zoneid
                        local someZoneType = child.Name
                        local isGoodId = ZoneConstants.ZoneType[someZoneCategory][someZoneType] and true or false
                        if not isGoodId then
                            warn(("%s does not match any known %s Id!"):format(child:GetFullName(), someZoneCategory))
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
        ZoneUtil.writeBasepartTotals(model)
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
    InstanceUtil.onDestroyed(model, function()
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

local function createCollisionHitbox(zone: ZoneConstants.Zone, departurePart: BasePart)
    local collisionName = ("%s_%s_%s_CollisionDisabler"):format(zone.ZoneCategory, zone.ZoneType, departurePart.Name)

    local collisionPart: BasePart = departurePart:Clone()
    collisionPart.Name = collisionName
    collisionPart.Size = collisionPart.Size + DEPARTURE_COLLISION_AREA_SIZE
    collisionPart.CanCollide = false
    collisionPart.Transparency = 1
    collisionPart.Parent = collisionDisablers

    local collisionHitbox = PlayersHitbox.new():AddPart(collisionPart)
    collisionHitbox.PlayerEntered:Connect(function(player)
        CharacterUtil.setEthereal(player, true, ETHEREAL_KEY_DEPARTURES)
    end)
    collisionHitbox.PlayerLeft:Connect(function(player)
        CharacterUtil.setEthereal(player, false, ETHEREAL_KEY_DEPARTURES)
    end)

    InstanceUtil.onDestroyed(departurePart, function()
        collisionHitbox:Destroy(true)
    end)
end

local function addCollisionControl(someModels: { Model })
    for _, model in pairs(someModels) do
        local zone = ZoneUtil.getZoneFromZoneModel(model)
        local departures = {
            ZoneUtil.getDepartures(zone, ZoneConstants.ZoneCategory.Minigame),
            ZoneUtil.getDepartures(zone, ZoneConstants.ZoneCategory.Room),
        }
        for _, departureDirectory: Instance in pairs(departures) do
            -- Loop current children
            for _, departurePart in pairs(departureDirectory:GetChildren()) do
                -- WARN: Not a BasePart?
                if not departurePart:IsA("BasePart") then
                    warn(("%q should be a BasePart?!"):format(departurePart:GetFullName()))
                    continue
                end

                createCollisionHitbox(zone, departurePart)
            end

            -- Handle new parts being added
            departureDirectory.ChildAdded:Connect(function(child)
                -- WARN: Not a BasePart?
                if not child:IsA("BasePart") then
                    warn(("%q should be a BasePart?!"):format(child:GetFullName()))
                    return
                end

                createCollisionHitbox(zone, child)
            end)
        end
    end
end

local function setupCollisions()
    -- Setup character collisions around departures
    collisionDisablers = Instance.new("Folder")
    collisionDisablers.Name = "ZoneCollisionDisablers"
    collisionDisablers.Parent = game.Workspace

    addCollisionControl(staticModels)
end

-------------------------------------------------------------------------------
--  API
-------------------------------------------------------------------------------

function ZoneSetup.setupCreatedZone(zoneModel: Model)
    verifyAndCleanModels({ zoneModel })
    writeBasePartTotals({ zoneModel })
    placeModelOnGrid(zoneModel)
    addCollisionControl({ zoneModel })
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
    setupCollisions()
end

return ZoneSetup
