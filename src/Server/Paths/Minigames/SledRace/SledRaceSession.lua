local SledRaceSession = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Shared.Maid)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SledRaceSled = require(Paths.Server.Minigames.SledRace.SledRaceSled)
local SledRaceMap = require(Paths.Server.Minigames.SledRace.SledRaceMap)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local QueueStationService = require(Paths.Server.Minigames.QueueStationService)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CurrencyService = require(Paths.Server.CurrencyService)

local XY = Vector3.new(1, 0, 1)
local CLIENT_STUD_DISCREPANCY_ALLOWANCE = 2

function SledRaceSession.new(...: any)
    local minigameSession = MinigameSession.new(...)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local map = minigameSession:GetMap()
    local collectables: Folder?

    local mapOrigin: CFrame = SledRaceUtil.getMapOrigin(map)
    local mapDirection: CFrame = mapOrigin.Rotation

    local stateMaid = Maid.new()
    minigameSession:GetMaid():GiveTask(stateMaid)

    local participantData: {
        [Player]: {
            Position: Vector3,
            Velocity: number,
            Coins: number,
            Speed: number,
        },
    }

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function applySpeedModifier(player: Player, addend: number)
        local data = participantData[player]

        data.Speed = math.clamp(data.Speed + addend, SledRaceConstants.MinSpeed, SledRaceConstants.MaxSpeed)

        -- reverse effects
        task.delay(SledRaceConstants.CollectableEffectDuration, function()
            data.Speed = math.clamp(data.Speed - addend, SledRaceConstants.MinSpeed, SledRaceConstants.MaxSpeed)
        end)
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded:Connect(function(participant: Player)
        CharacterUtil.setEthereal(participant, true, "SledRace")
        SledRaceSled.spawnSled(participant, minigameSession:GetPlayerSpawnPoint(participant))
    end)

    minigameSession.ParticipantRemoved:Connect(function(participant: Player, stillInGame: boolean)
        if stillInGame then
            SledRaceSled.removeSled(participant)
            CharacterUtil.setEthereal(participant, false, "SledRace")
        end

        if participantData then
            participantData[participant] = nil
        end
    end)

    -------------------------------------------------------------------------------
    -- States
    -------------------------------------------------------------------------------
    minigameSession:RegisterStateCallbacks(MinigameConstants.States.CoreCountdown, function()
        participantData = {}

        for _, participant in pairs(minigameSession:GetParticipants()) do
            local character = participant.Character
            participantData[participant] = {
                Coins = 0,
                Speed = SledRaceConstants.DefaultSpeed,
                Position = character.PrimaryPart.Position,
                Velocity = 0,
            }

            --[[
                We give them ownership earlier than we they're supposed to start moving so that there is no delay when the race starts
                The client decides when to start moving given the information the server provides it
                If the client exploits this, we catch it because we monitor velocity
            ]]
            local sledPhysics = character:WaitForChild(SledRaceConstants.SledName):WaitForChild("Physics")
            sledPhysics.Anchored = false
            sledPhysics:SetNetworkOwner(participant)
        end

        -- Validate speeds
        stateMaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
            for participant, data in pairs(participantData) do
                local character = participant.Character
                -- CONTINUE: Player left minigame
                if not character then
                    continue
                end

                local position: Vector3 = character.PrimaryPart.Position
                local velocity: number = (mapDirection:PointToObjectSpace(position - data.Position) * XY).Magnitude / dt

                data.Position = position
                data.Velocity = velocity

                -- TODO: Anti cheats class
            end
        end))

        collectables = SledRaceMap.loadCollectables(map)
        stateMaid:GiveTask(collectables)
    end)

    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Core, function()
        local startTime = os.clock()
        local finished: { Player } = {}

        for _, partipant in pairs(minigameSession:GetParticipants()) do
            SledRaceUtil.unanchorSled(partipant)
        end

        stateMaid:GiveTask(Remotes.bindEventTemp("SledRaceCollectableCollected", function(player: Player, collectable: Model)
            -- RETURN: Collectable has already been collected or doesn't exist anymore
            if collectable.Parent ~= collectables then
                return
            end

            -- RETURN: Collectable is in another minigame session
            if not minigameSession:IsPlayerParticipant(player) then
                return
            end

            local data = participantData[player]
            local character = player.Character

            local collectableCFrame: CFrame, collectableSize: Vector3 = collectable:GetBoundingBox()
            local characterCFrame: CFrame, characterSize: Vector3 = character:GetBoundingBox()

            local clientStudDiscrepancy = (mapDirection:ToObjectSpace(characterCFrame:ToObjectSpace(collectableCFrame)).Position * XY).Magnitude
                - math.max(collectableSize.X, collectableSize.Z)
                - math.max(characterSize.X, characterSize.Z)
                - data.Velocity * player:GetNetworkPing()

            -- RETURN: Collectable wasn't actually touched
            if clientStudDiscrepancy > CLIENT_STUD_DISCREPANCY_ALLOWANCE then
                return
            end

            if SledRaceUtil.collectableIsA(collectable, "Boost") then
                applySpeedModifier(player, SledRaceConstants.BoostSpeedAdded)
                collectable:Destroy()
                -- TODO: Play animation
            elseif SledRaceUtil.collectableIsA(collectable, "Obstacle") then
                applySpeedModifier(player, -SledRaceConstants.ObstacleSpeedMinuend)
                collectable:Destroy()
                -- TODO: Play animation
            elseif SledRaceUtil.collectableIsA(collectable, "Coin") then
                data.Coins += SledRaceConstants.CoinValue
            end
        end))

        stateMaid:GiveTask(map.Course.Finish.FinishLine.PrimaryPart.Touched:Connect(function(hit)
            local player = Players:GetPlayerFromCharacter(hit.Parent)
            if player and minigameSession:IsPlayerParticipant(player) and not table.find(finished, player) then
                table.insert(finished, player)
                minigameSession:IncrementScore(player, math.floor((os.clock() - startTime) * 10 ^ 2))

                if #finished == #minigameSession:GetParticipants() then
                    if minigameSession:GetState() == MinigameConstants.States.Core then
                        minigameSession:ChangeState(MinigameConstants.States.AwardShow)
                    end
                end
            end
        end))
    end, function()
        stateMaid:Cleanup()
    end)

    minigameSession:RegisterStateCallbacks(MinigameConstants.States.AwardShow, function()
        for participant, data in pairs(participantData) do
            local coins = data.Coins
            if coins then
                CurrencyService.addCoins(participant, coins, true)
            end
        end
        stateMaid:Cleanup()
        participantData = {}
    end, function()
        -- Respawn at spawn points
        for _, participant in pairs(minigameSession:GetParticipants()) do
            SledRaceSled.spawnSled(participant, minigameSession:GetPlayerSpawnPoint(participant))
        end
    end)

    minigameSession:SetDefaultScore(SledRaceConstants.SessionConfig.CoreLength)
    minigameSession:Start()

    return minigameSession
end

-------------------------------------------------------------------------------
-- Queue stations
-------------------------------------------------------------------------------
for _, station in pairs(Workspace.Rooms.SkiHill.QueueStations:GetChildren()) do
    QueueStationService.resetStatusBoard(
        station,
        TableUtil.overwrite(MinigameUtil.getsessionConfig("SledRace"), MinigameUtil.getSessionConfigFromQueueStation(station))
    )
end

return SledRaceSession
