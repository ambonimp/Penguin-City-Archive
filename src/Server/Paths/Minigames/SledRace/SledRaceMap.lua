local SledRaceMap = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)

local COLLECTABLE_GRID = SledRaceConstants.CollectableGrid
local COLLECTABLE_TYPES = SledRaceConstants.Collectables
local COLLECTABLES_MARGINS = { Z = 90, X = 250 }
local MAX_COLLECTABLE_COUNT = COLLECTABLE_GRID.Z * COLLECTABLE_GRID.X
local COINS_IN_COLLECTABLE = SledRaceConstants.CoinsPerCollectable

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()

local assets: Folder = ServerStorage.Minigames.SledRace
local mapTemplate: Model = assets.Map
local collectableTemplates: Folder = assets.Collectables

local mapTemplateOrigin: CFrame = SledRaceUtil.getMapOrigin(mapTemplate)
local mapTemplateDirection: CFrame = mapTemplateOrigin.Rotation

local spawnPoints: { CFrame } = {}
local rowPadding: number

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
-- Populates a map with collectables it with collectables using spawn points
function SledRaceMap.loadCollectables(map: Model)
    local mapOrigin: CFrame = SledRaceUtil.getMapOrigin(map)

    local collectables = Instance.new("Folder")
    collectables.Name = "Collectables"
    collectables.Parent = map

    local unusedSpawnPoints = TableUtil.deepClone(spawnPoints)
    local function spawnCollectable(templates: { Model })
        local spawnIndex = random:NextInteger(1, #unusedSpawnPoints)
        local spawnPoint: CFrame = unusedSpawnPoints[spawnIndex] :: CFrame
        table.remove(unusedSpawnPoints, spawnIndex)

        local template = templates[random:NextInteger(1, #templates)]
        local cframe: CFrame, size: Vector3 = template:GetBoundingBox()
        local deph: number = size.Z
        local maxZOffset: number = (rowPadding - deph) * (3 / 4)

        local base: CFrame = mapOrigin:ToWorldSpace(spawnPoint)
            * CFrame.new(cframe:PointToObjectSpace(template.WorldPivot.Position) + Vector3.new(0, size.Y / 2, 0))
        if SledRaceUtil.collectableIsA(template, "Coin") then
            local padding = maxZOffset / (COINS_IN_COLLECTABLE - 1)

            for i = 1, COINS_IN_COLLECTABLE do
                local collectable = template:Clone()
                collectable:PivotTo(base * CFrame.new(Vector3.new(0, 0, -padding * (i - 1))))
                collectable.Parent = collectables
            end
        else
            local collectable = template:Clone()
            collectable:PivotTo(base * CFrame.new(Vector3.new(0, 0, -(deph / 2) - ((maxZOffset / 6) * random:NextInteger(0, 3)))))
            collectable.Parent = collectables
        end
    end

    for collectableType, info in pairs(COLLECTABLE_TYPES) do
        local spawning: number = math.floor(MAX_COLLECTABLE_COUNT * info.Occupancy)
        for _ = 1, spawning do
            spawnCollectable(collectableTemplates[collectableType .. "s"]:GetChildren())
        end
    end

    return collectables
end

-------------------------------------------------------------------------------
-- TEMPLATES
-------------------------------------------------------------------------------
-- Collectables
do
    for _, descedant in ipairs(collectableTemplates:GetDescendants()) do
        if descedant:IsA("BasePart") then
            descedant.CanCollide = true
            descedant.Anchored = true
            PhysicsService:SetPartCollisionGroup(descedant, CollisionsConstants.Groups.SledRaceCollectables)
        elseif descedant:IsA("Model") then
            local collectableType: string = descedant.Parent.Name:sub(1, -2)
            local info = COLLECTABLE_TYPES[collectableType]
            if info then
                descedant:SetAttribute("CollectableType", COLLECTABLE_TYPES[collectableType].Tag)
            end
        end
    end
end

-- Set up all the potential spawn points and save them in a table
do
    mapTemplate.Parent = Workspace

    local slope: Model = mapTemplate.Slope
    local slopeSize: Vector3, slopeCFrame: CFrame = SledRaceUtil.getSlopeBoundingBox(mapTemplate)

    local collectablesLength = (slopeSize.Z - COLLECTABLES_MARGINS.Z * 2)
    local rowsOrigin: CFrame = CFrame.new(slopeCFrame.Position)
        * mapTemplateDirection
        * CFrame.new(0, slopeSize.Y / 2, collectablesLength / 2)
    rowPadding = collectablesLength / COLLECTABLE_GRID.Z

    local collectablesWidth = (slopeSize.X - COLLECTABLES_MARGINS.X * 2)
    local columPadding = collectablesWidth / (COLLECTABLE_GRID.X - 1)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { slope }
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local function getNormalIncline(raycastResults: RaycastResult): CFrame
        local v1: Vector3 = Vector3.new(0, 1, 0)
        local v2: Vector3 = raycastResults.Normal
        return mapTemplateDirection * CFrame.Angles(-math.acos(math.clamp(v1:Dot(v2), -1, 1)) / (v2.Magnitude * v2.Magnitude), 0, 0)
    end

    for i = 1, COLLECTABLE_GRID.Z do
        local rowCenter: Vector3 = rowsOrigin:PointToWorldSpace(Vector3.new(0, 0, -(i - 1) * rowPadding))
        local raycastResults = Workspace:Raycast(rowCenter, Vector3.new(0, -1, 0) * slopeSize.Y, raycastParams)
        local columnsOrigin = CFrame.new(raycastResults.Position)
            * getNormalIncline(raycastResults)
            * CFrame.new(-(COLLECTABLE_GRID.X - 1) * columPadding / 2, 0, 0)

        for j = 1, COLLECTABLE_GRID.X do
            local cframe = mapTemplateOrigin:ToObjectSpace(columnsOrigin * CFrame.new((j - 1) * columPadding, 0, 0))
            table.insert(spawnPoints, cframe)
        end
    end

    mapTemplate.Parent = assets
end

return SledRaceMap
