local SledRaceSession = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SledRaceSled = require(Paths.Server.Minigames.SledRace.SledRaceSled)
local SledRaceMap = require(Paths.Server.Minigames.SledRace.SledRaceMap)

local XY = Vector3.new(1, 0, 1)
local CLIENT_STUD_DISCREPANCY_ALLOWANCE = 2

function SledRaceSession.new(id: string, participants: { Player })
    local minigameSession = MinigameSession("SledRace", id, participants)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local map = minigameSession:GetMap()
    local spawnPoints = map.SpawnPoints:GetChildren()
    local collectables: Folder?

    local mapOrigin: CFrame = SledRaceUtil.getMapOrigin(map)
    local mapDirection: CFrame = mapOrigin.Rotation

    local stateMachine = minigameSession:GetState()
    local stateMaid = Maid.new()

    local maid = minigameSession:GetMaid()
    maid:GiveTask(stateMaid)

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
        SledRaceSled.spawnSled(participant, spawnPoints[table.find(participants, participant)])
    end)

    minigameSession.ParticipantRemoved:Connect(function(participant: Player)
        SledRaceSled.removeSled(participant)
    end)

    -------------------------------------------------------------------------------
    -- States
    -------------------------------------------------------------------------------
    stateMachine:RegisterStateCallbacks(MinigameConstants.States.Intermission, function()
        -- Respawn at spawn points
        for i, participant in pairs(participants) do
            SledRaceSled.spawnSled(participant, spawnPoints[i])
        end
    end)

    stateMachine:RegisterStateCallbacks(MinigameConstants.States.CoreCountdown, function()
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
            SledRaceUtil.getSled(participant).PrimaryPart:SetNetworkOwner(participant)
        end

        -- Validate speeds
        stateMaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
            for particpant, data in pairs(participantData) do
                local character = particpant.Character

                local position: Vector3 = character.PrimaryPart.Position
                local velocity: number = (mapDirection:PointToObjectSpace(position - data.Position) * XY).Magnitude / dt

                data.Position = position
                data.Velocity = velocity

                -- TODO: Anti cheats
            end
        end))

        collectables = SledRaceMap.loadCollectables(map)
        stateMaid:GiveTask(collectables)
    end)

    stateMachine:RegisterStateCallbacks(MinigameSession.States.Core, function()
        for _, partipant in pairs(participants) do
            SledRaceUtil.unanchorSled(partipant)
        end

        stateMaid:GiveTask(Remotes.bindEventTemp("OnSledRaceCollectableCollected", function(player: Player, collectable: Model)
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

            -- RETURN: Obstacle wasn't actually touched
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
    end, function()
        stateMaid:Destroy()
    end)

    stateMachine:RegisterStateCallbacks(MinigameSession.States.AwardShow, function()
        -- TODO
        stateMaid:Cleanup()
    end, function()
        participantData = {}
        stateMaid:Cleanup()
    end)

    return minigameSession
end

return SledRaceSession
