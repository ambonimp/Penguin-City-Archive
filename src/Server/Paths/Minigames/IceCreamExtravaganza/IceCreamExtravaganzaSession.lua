local IceCreamExtravaganzaSession = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

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

local SCOOP_INSET = 0.6
local CONE_HOLD_ANIMATION = InstanceUtil.tree("Animation", { Name = "ConeHold", AnimationId = "rbxassetid://11624834749" })

local CLIENT_STUD_DISCREPANCY_ALLOWANCE = 2

local random = Random.new()

local serverAssets = ServerStorage.Minigames[MINIGAME_NAME]
local replicatedAssets = ReplicatedStorage.Assets.Minigames[MINIGAME_NAME]

local collectableModels: { [string]: { Model } } = {}

function IceCreamExtravaganzaSession.new(...: any)
    local minigameSession = MinigameSession.new(...)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local coreMaid = Maid.new()
    local minigameMaid = minigameSession:GetMaid()
    minigameMaid:GiveTask(minigameMaid)

    local map = minigameSession:GetMap()
    local collectableSpawns = map.CollectableSpawns:GetChildren()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function clearCone(participant: Player)
        local character: Model = participant.Character
        local cone: Model = character:FindFirstChild("Cone")
        if cone then
            cone:Destroy()
        end

        for _, track in pairs(character.Humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Name == CONE_HOLD_ANIMATION.Name then
                track:Stop(0)
                track:Destroy()
            end
        end
    end

    local function spawnCharacter(participant: Player)
        local character: Model = participant.Character
        local humanoidRootPart = character.HumanoidRootPart

        CharacterUtil.standOn(character, minigameSession:GetPlayerSpawnPoint(participant))

        clearCone(participant)

        local cone: Model = serverAssets.Cone:Clone()
        cone.Parent = character
        local conePrimary: BasePart = cone.PrimaryPart
        conePrimary.Massless = true
        cone:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 0, -(1 + conePrimary.Size.Z / 2)))
        BasePartUtil.weld(conePrimary, humanoidRootPart)

        local track = character.Humanoid.Animator:LoadAnimation(CONE_HOLD_ANIMATION)
        track:Play(0, 11)
    end

    local function getScoopName(index: number)
        return MINIGAME_NAME .. index
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded:Connect(function(participant: Player)
        PropertyStack.setProperty(
            participant.Character.Humanoid,
            "WalkSpeed",
            IceCreamExtravaganzaConstants.WalkSpeed,
            PROPERTY_STACK_KEY_SPEED,
            math.huge
        )
        spawnCharacter(participant)
    end)

    minigameSession.ParticipantRemoved:Connect(function(participant: Player, stillInGame: boolean)
        if stillInGame then
            local character: Model = participant.Character
            clearCone(participant)
            CharacterUtil.unanchor(character)

            PropertyStack.clearProperty(character.Humanoid, "WalkSpeed", PROPERTY_STACK_KEY_SPEED)
        end
    end)

    -------------------------------------------------------------------------------
    -- State handlers
    -------------------------------------------------------------------------------
    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Intermission, function()
        for _, participant in pairs(minigameSession:GetParticipants()) do
            spawnCharacter(participant)
        end
    end)

    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Core, function()
        local collectables: { [string]: Collectable } = {}
        local idCounter: number = 0

        local inviciblePlayers = {}

        -- Spawn collectables
        local collectaleSpawningThread = task.spawn(function()
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
        end)

        coreMaid:GiveTask(function()
            task.cancel(collectaleSpawningThread)
        end)

        coreMaid:GiveTask(Remotes.bindEventTemp("IceCreamExtravaganzaCollectableCollected", function(player: Player, collectableId: string)
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

            local coneCFrame: CFrame = cone:GetBoundingBox()
            local characterSize: Vector3 = character:GetExtentsSize()
            local collectableSize: Vector3 = collectableModel:GetExtentsSize()
            local collectablePosition: Vector3 = collectable.DropOrigin
                - Vector3.new(0, IceCreamExtravaganzaConstants.DropVelocity * (collectable.SpawnTime - os.clock()), 0)

            local clientStudDiscrepancy = Vector3Util.getXZComponents((coneCFrame:PointToObjectSpace(collectablePosition))).Magnitude
                - math.max(collectableSize.X, collectableSize.Z)
                - math.max(characterSize.X, characterSize.Z)
                - character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude * player:GetNetworkPing()

            -- RETURN: Collectable wasn't actually touched
            if clientStudDiscrepancy > CLIENT_STUD_DISCREPANCY_ALLOWANCE then
                warn("NOT REGESTERING", clientStudDiscrepancy)
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

                    local newScore, oldScore = minigameSession:IncrementScore(player, -1)
                    if newScore ~= 0 then
                        cone[getScoopName(oldScore)]:Destroy()
                    end
                elseif collectableType == "Invicible" then
                    -- RETURN: Player is already invisible
                    if inviciblePlayers[player] then
                        return
                    end

                    local descendantMaid = DescendantLooper.add(function(descendant)
                        return descendant:IsA("BasePart")
                    end, function(descendant: BasePart)
                        PropertyStack.setProperties(descendant, INVICIBILITY_PROPERTIES, PROPERTY_STACK_KEY_INVICIBLE, math.huge)
                    end, { character })

                    inviciblePlayers[player] = function()
                        if inviciblePlayers[player] then
                            inviciblePlayers[player] = nil
                            descendantMaid:Destroy()

                            for _, descendant in pairs(character:GetDescendants()) do
                                if descendant:IsA("BasePart") then
                                    PropertyStack.clearProperties(descendant, INVICIBILITY_PROPERTIES, PROPERTY_STACK_KEY_INVICIBLE)
                                end
                            end
                        end
                    end

                    local revertThread = task.delay(IceCreamExtravaganzaConstants.InvicibilityLength, inviciblePlayers[player])
                    coreMaid:GiveTask(function()
                        task.cancel(revertThread)
                    end)
                else
                    local scoreAddend = if collectableType == "Regular" then 1 else 2

                    local _, oldScore = minigameSession:IncrementScore(player, scoreAddend)
                    for i = 1, scoreAddend do
                        local lastScoop: Model = if i == 1 then cone else cone[getScoopName(oldScore + i - 1)]
                        local lastScoopCFrame, lastScoopSize = lastScoop:GetBoundingBox()
                        local pivotCFrame: CFrame = CFrame.new(0, lastScoopSize.Y / 2 - SCOOP_INSET, 0) * lastScoopCFrame

                        local scoop: Model = collectableModel:Clone()
                        local scoopPrimary: BasePart = scoop.PrimaryPart
                        scoop.Name = getScoopName(oldScore + i)
                        scoop:PivotTo(ModelUtil.getWorldPivotToCenter(scoop, CFrame.new(0, collectableSize.Y / 2, 0) * pivotCFrame))
                        scoop.Parent = cone

                        local att0: Attachment = Instance.new("Attachment")
                        att0.Parent = scoopPrimary
                        att0.WorldCFrame = pivotCFrame

                        local att1: Attachment = Instance.new("Attachment")
                        att1.Parent = lastScoop.PrimaryPart
                        att1.WorldCFrame = pivotCFrame

                        local ballSocket = Instance.new("BallSocketConstraint")
                        ballSocket.Attachment0 = att0
                        ballSocket.Attachment1 = att1
                        ballSocket.LimitsEnabled = true
                        ballSocket.UpperAngle = 10
                        ballSocket.TwistLimitsEnabled = true
                        ballSocket.TwistLowerAngle = 0
                        ballSocket.TwistUpperAngle = 0
                        ballSocket.Parent = scoopPrimary
                    end
                end
            end)
        end))

        coreMaid:GiveTask(function()
            for _, invicibleReverter in pairs(inviciblePlayers) do
                invicibleReverter()
            end
        end)

        coreMaid:GiveTask(minigameSession.ParticipantRemoved:Connect(function(participant: Player, stillInGame: boolean)
            local invicibleReverter = inviciblePlayers[participant]
            if stillInGame and invicibleReverter then
                invicibleReverter()
            end
        end))

        --
    end, function()
        if minigameSession:GetState() ~= MinigameConstants.States.Core then
            coreMaid:Cleanup()
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
    for _, weightedChoice in pairs(IceCreamExtravaganzaConstants.CollectableDropProbability) do
        local collectableType = weightedChoice.Value

        local models = replicatedAssets.Collectables[collectableType]:GetChildren()
        collectableModels[collectableType] = models

        for _, model in ipairs(models) do
            model:SetAttribute("Type", collectableType)

            local primaryPart: BasePart
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    if not primaryPart then
                        primaryPart = descendant
                    else
                        BasePartUtil.weld(descendant, primaryPart)
                    end

                    descendant.Anchored = false
                    descendant.CanCollide = false
                    descendant.CanQuery = false
                    descendant.CanTouch = true
                    descendant.Massless = true

                    descendant.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
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
        collectableSpawn.Transparency = 1
        local position: Vector3 = collectableSpawn.Position
        collectableSpawn.Position = Vector3.new(position.X, height, position.Z)
    end

    local collectableContainer = Instance.new("Folder")
    collectableContainer.Name = IceCreamExtravaganzaConstants.CollectableContainerName
    collectableContainer.Parent = mapTemplate

    mapTemplate.Floor.CustomPhysicalProperties = IceCreamExtravaganzaConstants.FloorPhysicalProperties
end

do
    Remotes.declareEvent("IceCreamExtravaganzaCollectableSpawned")
    Remotes.declareEvent("IceCreamExtravaganzaCollectableCollected")
end

return IceCreamExtravaganzaSession
