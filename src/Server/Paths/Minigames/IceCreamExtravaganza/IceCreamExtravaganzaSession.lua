local IceCreamExtravaganzaSession = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local Janitor = require(Paths.Packages.janitor)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CharacterController = require(Paths.Server.Characters.CharacterService)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local Output = require(Paths.Shared.Output)

type Collectable = {
    Id: string,
    Type: string,
    DropOrigin: Vector3,
    Model: Model,
    SpawnTime: number,
}

local MINIGAME_NAME = "IceCreamExtravaganza"

local PROPERTY_STACK_KEY_SPEED = "IceCreamExtravaganza_Speed"
local PROPERTY_STACK_KEY_INVICIBLE = "IceCreamExtravaganza_Invicible"
local INVICIBILITY_PROPERTIES = {
    Material = Enum.Material.ForceField,
    Color = Color3.new(1, 1, 1),
}

local CLIENT_STUD_DISCREPANCY_ALLOWANCE = 2

local random = Random.new()

local serverAssets = ServerStorage.Minigames[MINIGAME_NAME]
local replicatedAssets = ReplicatedStorage.Assets.Minigames[MINIGAME_NAME]

local collectableModels: { [string]: { Model } } = {}

function IceCreamExtravaganzaSession.new(id: string, participants: { Player }, isMultiplayer: boolean)
    local minigameSession = MinigameSession.new(MINIGAME_NAME, id, participants, isMultiplayer)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local coreJanitor = Janitor.new()
    local minigameJanitor = minigameSession:GetJanitor()
    minigameJanitor:Add(minigameJanitor)

    local map = minigameSession:GetMap()
    local collectableSpawns = map.CollectableSpawns:GetChildren()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function clearCone(participant: Player)
        local cone: Model = participant.Character:FindFirstChild("Cone")
        if cone then
            cone:Destroy()
        end
    end

    local function spawnCharacter(participant: Player)
        local character: Model = participant.Character
        local humanoid: Humanoid = character.Humanoid
        local humanoidRootPart = character.HumanoidRootPart

        PropertyStack.setProperty(humanoid, "WalkSpeed", IceCreamExtravaganzaConstants.WalkSpeed, PROPERTY_STACK_KEY_SPEED, math.huge)
        CharacterController.standOn(character, minigameSession:GetPlayerSpawnPoint(participant))

        clearCone(participant)
        local cone: Model = serverAssets.Cone:Clone()
        cone.Parent = character
        local conePrimary: BasePart = cone.PrimaryPart
        cone:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 0, -(1 + conePrimary.Size.Z / 2)))
        BasePartUtil.weld(conePrimary, humanoidRootPart)
    end

    local function getScoopName(index: number)
        return MINIGAME_NAME .. index
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded:Connect(function(participant: Player)
        spawnCharacter(participant)
    end)

    minigameSession.ParticipantRemoved:Connect(function(participant: Player, stillInGame: boolean)
        if stillInGame then
            local character: Model = participant.Character
            CharacterUtil.unanchor(character)

            PropertyStack.clearProperty(character.Humanoid, "WalkSpeed", PROPERTY_STACK_KEY_SPEED)
        end
    end)

    -------------------------------------------------------------------------------
    -- State handlers
    -------------------------------------------------------------------------------
    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Intermission, function()
        for _, participant in pairs(participants) do
            spawnCharacter(participant)
        end
    end)

    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Core, function()
        local collectables: { [string]: Collectable } = {}
        local idCounter: number = 0

        local inviciblePlayers = {}

        -- Spawn collectables
        coreJanitor:Add(task.spawn(function()
            while true do
                idCounter += 1

                local collectableId = tostring(idCounter)
                local collectableDropOrigin = collectableSpawns[random:NextInteger(1, #collectableSpawns)].Position
                local collectableType = MathUtil.weightedChoice(IceCreamExtravaganzaConstants.CollectableDropProbability)
                local collectableModel = collectableModels[collectableType][random:NextInteger(1, #collectableModels[collectableType])]

                local collectable: Collectable = {
                    Id = collectableId,
                    DropOrigin = collectableDropOrigin,
                    Type = collectableType,
                    Model = collectableModel,
                    SpawnTime = os.clock(),
                }

                collectables[collectableId] = collectable
                minigameSession:RelayToParticipants(
                    "IceCreamExtravaganzaCollectableSpawned",
                    collectableId,
                    collectableModel,
                    CFrame.new(collectableDropOrigin) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
                )

                task.wait(IceCreamExtravaganzaConstants.CollectableDropRate)
            end
        end))

        coreJanitor:Add(Remotes.bindEventTemp("IceCreamExtravaganzaCollectableCollected", function(player: Player, collectableId: string)
            local character: Model = player.Character

            -- RETURN: Wrong session
            if not minigameSession:IsPlayerParticipant(player) then
                return
            end

            local collectable = collectables[collectableId]
            -- RETURN: Collectable already collected
            if not collectable then
                return
            end

            local cone: Model = character.Cone
            local collectableModel: Model = collectable.Model

            local collectableSize: Vector3 = collectableModel:GetExtentsSize()
            local coneCFrame: CFrame, coneSize: Vector3 = cone:GetBoundingBox()
            local collectablePosition: Vector3 = collectable.DropOrigin
                - Vector3.new(0, IceCreamExtravaganzaConstants.DropVelocity * (collectable.SpawnTime - os.clock()), 0)

            local clientStudDiscrepancy = Vector3Util.getXZComponents((coneCFrame:PointToObjectSpace(collectablePosition))).Magnitude
                - math.max(collectableSize.X, collectableSize.Z)
                - math.max(coneSize.X, coneSize.Z)
                - character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude * player:GetNetworkPing()

            -- RETURN: Collectable wasn't actually touched
            if clientStudDiscrepancy > CLIENT_STUD_DISCREPANCY_ALLOWANCE then
                return
            end

            task.defer(function()
                -- Apply effects
                local collectableType: string = collectable.Type
                if collectableType == "Obstacle" then
                    -- RETURN: Player is invisible
                    if inviciblePlayers[player] then
                        return
                    end

                    local _, oldScore = minigameSession:IncrementScore(player, -1)
                    cone:FindFirstChild(getScoopName(oldScore)):Destroy()
                elseif collectableType == "Invicible" then
                    -- RETURN: Player is already invisible
                    if inviciblePlayers[player] then
                        return
                    end

                    local descedantAddedHandlerCleanup = DescendantLooper.add(function(descendant)
                        return descendant:IsA("BasePart")
                    end, function(descendant: BasePart)
                        PropertyStack.setProperties(descendant, INVICIBILITY_PROPERTIES, PROPERTY_STACK_KEY_INVICIBLE, math.huge)
                    end, { character })

                    inviciblePlayers[player] = function()
                        inviciblePlayers[player] = nil
                        for _, descendant in pairs(descedantAddedHandlerCleanup()) do
                            PropertyStack.clearProperties(descendant, INVICIBILITY_PROPERTIES, PROPERTY_STACK_KEY_INVICIBLE)
                        end
                    end

                    coreJanitor:Add(task.delay(IceCreamExtravaganzaConstants.InvicibilityLength, inviciblePlayers[player]))
                else
                    local scoreAddend = if collectableType == "Regular" then 1 else 2

                    local _, oldScore = minigameSession:IncrementScore(player, scoreAddend)
                    for i = 1, scoreAddend do
                        local lastScoopCFrame, lastScoopSize = (if i == 1 then cone else cone[getScoopName(oldScore + i - 1)]):GetBoundingBox()

                        local scoop: Model = collectableModel:Clone()
                        local scoopPrimary = scoop.PrimaryPart
                        scoop.Name = getScoopName(oldScore + i)
                        scoop:PivotTo(
                            ModelUtil.getWorldPivotToCenter(
                                scoop,
                                CFrame.new(0, (lastScoopSize + collectableSize).Y / 2, 0) * lastScoopCFrame
                            )
                        )
                        scoop.Parent = cone
                        scoopPrimary.Anchored = false
                        BasePartUtil.weld(scoopPrimary, cone.PrimaryPart)
                    end
                end
            end)
        end))

        coreJanitor:Add(function()
            for _, invicibleReverter in pairs(inviciblePlayers) do
                invicibleReverter()
            end
        end)

        --
    end, function()
        if minigameSession:GetState() ~= MinigameConstants.States.Core then
            coreJanitor:Cleanup()
        end
    end)

    minigameSession:SetDefaultScore(0)
    minigameSession:Start()

    return minigameSession
end

-------------------------------------------------------------------------------
-- Template set up
-------------------------------------------------------------------------------
-- Collectables
do
    for collectableType in pairs(IceCreamExtravaganzaConstants.CollectableDropProbability) do
        local models = replicatedAssets.Collectables[collectableType]:GetChildren()
        collectableModels[collectableType] = models

        for _, model in ipairs(models) do
            model:SetAttribute("Type", collectableType)

            local primaryPart: BasePart
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    if not primaryPart then
                        primaryPart = descendant
                        primaryPart.Anchored = true
                    else
                        descendant.Anchored = false
                        BasePartUtil.weld(descendant, primaryPart)
                    end

                    descendant.CanCollide = false
                    descendant.CanQuery = false
                    descendant.CanTouch = true
                    descendant.Massless = true
                end
            end
        end
    end
end

-- Map
do
    local mapTemplate: Model = serverAssets.Map
    local collectableSpawns: Model = mapTemplate.CollectableSpawns
    local height: number = collectableSpawns.WorldPivot.Position.Y

    for _, collectableSpawn in pairs(collectableSpawns:GetChildren()) do
        local position: Vector3 = collectableSpawn.Position
        collectableSpawn.Position = Vector3.new(position.X, height, position.Z)
    end

    local collectableContainer = Instance.new("Folder", mapTemplate)
    collectableContainer.Name = IceCreamExtravaganzaConstants.CollectableContainerName
    collectableContainer.Parent = mapTemplate
end

do
    Remotes.declareEvent("IceCreamExtravaganzaCollectableSpawned")
    Remotes.declareEvent("IceCreamExtravaganzaCollectableCollected")
end

return IceCreamExtravaganzaSession
