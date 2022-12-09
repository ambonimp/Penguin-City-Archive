local MinigameSession = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Janitor = require(Paths.Packages.janitor)
local Signal = require(Paths.Shared.Signal)
local Remotes = require(Paths.Shared.Remotes)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local StateMachine = require(Paths.Shared.StateMachine)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local CurrencyService = require(Paths.Server.CurrencyService)
local Output = require(Paths.Shared.Output)
local DataService = require(Paths.Server.Data.DataService)

type Participants = { Player }

local STATES = MinigameConstants.States

local assets = ServerStorage.Minigames

function MinigameSession.new(
    minigameName: string,
    id: string,
    startingParticipants: Participants,
    isMultiplayer: boolean,
    queueStation: Model?
)
    local minigameSession = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local janitor = Janitor.new()
    local stateMachine = StateMachine.new(TableUtil.getKeys(STATES), STATES.Nothing)
    janitor:Add(stateMachine)

    local zone: ZoneConstants.Zone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Minigame, ZoneConstants.ZoneType.Minigame[minigameName], id)
    local map: Model = assets[minigameName].Map:Clone()
    janitor:Add((ZoneService.createZone(zone, { map }, map.PrimaryPart:Clone())))

    local playerSpawns: { BasePart }? = if map:FindFirstChild("PlayerSpawns") then map.PlayerSpawns:GetChildren() else nil
    local playerSpawnRandomizer: number = 0

    local participants: Participants = {}
    local scores: { [Player]: number? }?
    local scoreRange = { Min = 0, Max = math.huge }

    local config: MinigameConstants.SessionConfig =
        TableUtil.merge(MinigameUtil.getsessionConfig(minigameName), MinigameUtil.getSessionConfigFromQueueStation(queueStation))

    local defaultScore: number?
    local started: boolean = false

    local random = Random.new()

    -------------------------------------------------------------------------------
    -- PUBLIC MEMBERS
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded = Signal.new()
    minigameSession.ParticipantRemoved = Signal.new()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function getOtherParticipants(exception: Player): Participants
        local others = {}

        for _, participant in pairs(participants) do
            if participant ~= exception then
                table.insert(others, participant)
            end
        end

        return others
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function minigameSession:GetJanitor()
        return janitor
    end

    function minigameSession:GetState(): string
        return stateMachine:GetState()
    end

    function minigameSession:ChangeState(state: string)
        if stateMachine:GetState() ~= STATES.Nothing then
            stateMachine:Pop()
        end

        stateMachine:Push(state)
    end

    function minigameSession:RegisterStateCallbacks(state: string, onOpen: (table) -> ()?, onClose: (table) -> ()?)
        if started then
            warn(
                ("%s minigame attempting to register %s callback after the minigame was started. NOTE: State changes will be relayed to the client before these handlers are invoked."):format(
                    minigameName,
                    state
                )
            )
        end

        stateMachine:RegisterStateCallbacks(state, onOpen, onClose)
    end

    function minigameSession:GetMap(): Model
        return map
    end

    function minigameSession:GetPlayerSpawnPoint(participant: Player): BasePart
        -- ERROR: Player doesn't belong to this minigame
        if not minigameSession:IsPlayerParticipant(participant) then
            error(minigameName .. " minigame attempting to get a spawn point for a player who isn't participanting in the session")
        end

        -- ERROR: No spawn points
        if not playerSpawns then
            error(minigameName .. " minigame doesn't have player spawn points. Spawn points should be in a folder called PlayerSpawns")
        end

        -- ERROR: Not enough player spawns
        if #playerSpawns < config.MaxParticipants then
            error(
                ("%s minigame doesn't have enough player spawn points. Only has %d/%d"):format(
                    minigameName,
                    #playerSpawns,
                    config.MaxParticipants
                )
            )
        end

        return playerSpawns[math.max(1, (table.find(participants, participant) + playerSpawnRandomizer) % #playerSpawns)]
    end

    function minigameSession:RelayToParticipants(eventName: string, ...: any)
        Remotes.fireClients(participants, eventName, ...)
    end

    function minigameSession:RelayToOtherParticipants(exception: Player, eventName: string, ...: any)
        Remotes.fireClients(getOtherParticipants(exception), eventName, ...)
    end

    function minigameSession:IsPlayerParticipant(player: Player)
        return table.find(participants, player) ~= nil
    end

    function minigameSession:AddParticipant(player: Player)
        local teleportBuffer = ZoneService.teleportPlayerToZone(player, zone)
        -- RETURN: Player could not be teleported to map
        if not teleportBuffer then
            return
        end

        task.wait(teleportBuffer)

        table.insert(participants, player)
        minigameSession.ParticipantAdded:Fire(player)
        minigameSession:RelayToOtherParticipants(player, "MinigameParticipantAdded", player)

        Output.doDebug(MinigameConstants.DoDebug, "Participant joined", player.Name)

        Remotes.fireClient(
            player,
            "MinigameJoined",
            id,
            minigameName,
            { Name = stateMachine:GetState(), Data = stateMachine:GetData() },
            minigameSession:GetParticipants(),
            isMultiplayer
        )

        janitor:Add(player.Character.Humanoid.Died:Connect(function()
            minigameSession:RemoveParticipant(player)
        end))
    end

    function minigameSession:RemoveParticipant(player)
        -- RETURN: Player is not a participant
        if not minigameSession:IsPlayerParticipant(player) then
            return
        end

        local stillInGame: boolean = player.Character ~= nil
        table.remove(participants, table.find(participants, player))

        if scores then
            scores[player] = nil
        end

        -- Player didn't leave the game
        if stillInGame then
            Remotes.fireClient(player, "MinigameExited", id)

            if TableUtil.shallowEquals(zone, ZoneService.getPlayerMinigame(player)) then
                ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerRoom(player))
            end
        end

        minigameSession.ParticipantRemoved:Fire(player, stillInGame)
        minigameSession:RelayToOtherParticipants(player, "MinigameParticipantRemoved", player, participants)

        local remainingParticipants = #participants
        if remainingParticipants == 0 then
            janitor:Destroy()
        else
            if remainingParticipants == config.MinParticipants - 1 and config.StrictlyEnforcePlayerCount then
                local state = stateMachine:GetState()
                if state == STATES.Core or state == STATES.CoreCountdown then
                    minigameSession:ChangeState(STATES.AwardShow) -- This will then go to WaitingForPlayers
                end
            end
        end
    end

    function minigameSession:GetParticipants(): Participants
        return participants
    end

    function minigameSession:IsAcceptingNewParticipants()
        local state = stateMachine:GetState()
        return isMultiplayer
            and (state == STATES.Intermission or state == STATES.AwardShow or state == STATES.WaitingForPlayers)
            and #participants < config.MaxParticipants
    end

    function minigameSession:CountdownSync(length: number): boolean
        local currentState = stateMachine:GetState()

        while currentState == stateMachine:GetState() and length > 0 do
            length -= 1
            task.wait(1)
        end

        return length == 0
    end

    function minigameSession:SetDefaultScore(score: number)
        defaultScore = score
    end

    function minigameSession:SetScoreRange(min: number, max: number)
        assert(min < max, ("%s score range is invalid bc min is not less than max"):format(minigameName))
        scoreRange = { Min = min, Max = max }
    end

    function minigameSession:IncrementScore(participant: Player, addend: number): (number, number)
        -- ERROR: State is invalid
        if stateMachine:GetState() ~= STATES.Core then
            error(("%s minigame attempting to set score outside of the core state : %s"):format(minigameName, debug.traceback()))
        end

        local oldScore = scores[participant] or 0
        local newScore = math.clamp(oldScore + addend, scoreRange.Min, scoreRange.Max)
        scores[participant] = newScore
        minigameSession:RelayToParticipants("MinigameScoreChanged", minigameSession:SortScores())

        return newScore, oldScore
    end

    function minigameSession:SortScores(): MinigameConstants.SortedScores
        local sortedScores = {}
        local unsorted = TableUtil.deepClone(scores)

        for _ = 1, #participants do
            local minScore: number = math.huge
            local minPlayer: Player?

            for player, score in pairs(unsorted) do
                if score < minScore then
                    minScore = score
                    minPlayer = player
                end
            end

            table.insert(sortedScores, { Player = minPlayer, Score = minScore })
            unsorted[minPlayer] = nil
        end

        if config.HigherScoreWins then
            sortedScores = ArrayUtil.flip(sortedScores)
        end

        return sortedScores
    end

    function minigameSession:Start() -- Ideally, all events have been connected and everything is ready to go when you run this
        -- ERROR: No default score was set
        if not defaultScore then
            error(minigameName .. " minigame doesn't have a default default score set")
        end

        for _, player in pairs(startingParticipants) do
            minigameSession:AddParticipant(player)
        end

        -- Called here so that any callbacks the actual minigame registers can get run before the client is notified
        stateMachine:RegisterGlobalCallback(function(_, toState)
            -- RETURN: This isn't actually the new state
            if toState == STATES.Nothing then
                return
            end

            Output.doDebug(MinigameConstants.DoDebug, "Minigame state changed", toState)

            local data = stateMachine:GetData()
            data.StartTime = Workspace:GetServerTimeNow()

            minigameSession:RelayToParticipants("MinigameStateChanged", { Name = toState, Data = data })
        end)

        if isMultiplayer then
            minigameSession:ChangeState(STATES.Intermission)
        else
            janitor:Add(Remotes.bindEventTemp("MinigameStarted", function(player)
                local state = stateMachine:GetState()

                if minigameSession:IsPlayerParticipant(player) and (state == STATES.AwardShow or state == STATES.Nothing) then
                    minigameSession:ChangeState(STATES.Intermission)
                end
            end))

            janitor:Add(Remotes.bindEventTemp("MinigameRestarted", function()
                minigameSession:ChangeState(STATES.Nothing)
            end))
        end

        started = true
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    -- Register state
    do
        stateMachine:RegisterStateCallbacks(STATES.WaitingForPlayers, function()
            minigameSession.WaitingForPlayers = minigameSession.ParticipantAdded:Connect(function()
                if #participants >= config.MinParticipants then
                    minigameSession:ChangeState(STATES.Intermission)
                end
            end)
        end)

        stateMachine:RegisterStateCallbacks(STATES.Intermission, function()
            if isMultiplayer then
                -- RETURN: Waiting for more players
                if #participants < config.MinParticipants then
                    minigameSession:ChangeState(STATES.WaitingForPlayers)
                    return
                end

                -- RETURN: This is no longer the state
                if not minigameSession:CountdownSync(config.IntermissionLength) then
                    return
                end
            end

            if config.CoreCountdown then
                minigameSession:ChangeState(STATES.CoreCountdown)
            else
                minigameSession:ChangeState(STATES.Core)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.CoreCountdown, function()
            if minigameSession:CountdownSync(MinigameConstants.CoreCountdownLength) then
                minigameSession:ChangeState(STATES.Core)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.Core, function()
            scores = {}

            local coreLength: number? = config.CoreLength
            if coreLength then
                if minigameSession:CountdownSync(config.CoreLength) then
                    minigameSession:ChangeState(STATES.AwardShow)
                end
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.AwardShow, function()
            for _, participant in pairs(participants) do
                if not scores[participant] then
                    scores[participant] = defaultScore
                end
            end

            local sortedScores = minigameSession:SortScores()

            -- Reward
            for placement, scoreInfo in pairs(sortedScores) do
                local player = scoreInfo.Player
                local score = scoreInfo.Score

                CurrencyService.addCoins(player, config.Reward(placement, score))

                local recordAddress = "MinigameRecords." .. minigameName
                local highscore = DataService.get(player, recordAddress) or defaultScore
                if config.HigherScoreWins then
                    if score > highscore then
                        DataService.set(player, recordAddress, score)
                        scoreInfo.NewBest = true
                    end
                else
                    if score < highscore then
                        DataService.set(player, recordAddress, score)
                        scoreInfo.NewBest = true
                    end
                end
            end

            -- Relay to client
            stateMachine:GetData().Scores = sortedScores

            -- Cleanup
            scores = nil

            if isMultiplayer and config.Loop then
                playerSpawnRandomizer = random:NextInteger(0, #playerSpawns)

                minigameSession:CountdownSync(config.AwardShowLength)
                minigameSession:ChangeState(STATES.Intermission)
            end
        end)
    end

    -- Leaving
    do
        janitor:Add(Remotes.bindEventTemp("MinigameExited", function(player)
            minigameSession:RemoveParticipant(player)
        end))

        janitor:Add(ZoneService.ZoneChanged:Connect(function(player)
            minigameSession:RemoveParticipant(player)
        end))

        janitor:Add(Players.PlayerRemoving:Connect(function(player)
            minigameSession:RemoveParticipant(player)
        end))
    end

    return minigameSession
end

for _, minigame in pairs(assets:GetChildren()) do
    local cameras = minigame.Map:FindFirstChild("Cameras")
    if cameras then
        for _, basePart in pairs(cameras:GetDescendants()) do
            if basePart:IsA("BasePart") then
                basePart.Transparency = 1
            end
        end
    end
end

return MinigameSession
