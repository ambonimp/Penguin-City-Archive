--[[
    Each minigame inherits from this class.

    A minigame session is built around a state machine. Client and client handlers listen to the following state changes and react accordingly:
        - Nothing (Only runs once)
            - In single-player minigames, the session remains in this still until the player presses play.
            - On the client, its state is always run before any other state.
            - Great for setting up things that will remain for the duration of the session like disabling jumping.
        - Intermission
            - A reset state, do things like reposition players for the new round
            - Allows new players to join the session (Multiplayer)
            - If the session doesn't have enough participants in the state, it will go to WaitingForPlayers ((Multiplayer)
            - If single player than this opens and closes instantly, stil nice for initializing certain things each round
        - CoreCountdown
            - 3, 2, 1, Go! -> Core
            - Useful if you want to combat latency.
                For example for a race, you would give the client ownership at this point while tracking that player doesn't move until the core state.
                But this means that all clients will start at the same time.
        - Core
            - Gameplay state
            - If the session config has StrictlyEnforcePlayerCount set to true, if the number of participants falls below the MinParticipants count, the state will end
        - WaitingForPlayers
            - Goes to intermission when enough players are in the session
        - award shows
            - Sends results to the client
            - For multiplayer sessions, transitions to intermission when (AwardShowLength) time has passed.
]]

local MinigameSession = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Shared.Maid)
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
local CurrencyUtil = require(Paths.Shared.Currency.CurrencyUtil)

type Participants = { Player }
export type MinigameSession = typeof(MinigameSession.new())

local STATES = MinigameConstants.States

MinigameSession.MinigameFinished = Signal.new() -- { minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScored }
MinigameSession.ParticipantedAdded = Signal.new() -- { minigameSession: MinigameSession.MinigameSession, participant: Player }

local assets = ServerStorage.Minigames

function MinigameSession.new(
    minigameName: string,
    id: string,
    startingParticipants: Participants,
    isMultiplayer: boolean,
    queueStation: Model?
)
    local minigameSession = {}
    Output.doDebug(MinigameConstants.DoDebug, ("%s minigame session create joined ( %s )"):format(minigameName, id))

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local maid = Maid.new()

    local stateMachine = StateMachine.new(TableUtil.getKeys(STATES), STATES.Nothing)
    maid:GiveTask(stateMachine)

    local zone: ZoneConstants.Zone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Minigame, ZoneConstants.ZoneType.Minigame[minigameName], id)
    local map: Model = assets[minigameName].Map:Clone()
    maid:GiveTask((ZoneService.createZone(zone, { map }, map.PrimaryPart:Clone())))

    local playerSpawns: { BasePart }? = if map:FindFirstChild("PlayerSpawns") then map.PlayerSpawns:GetChildren() else nil
    local playerSpawnRandomizer: number = 0

    local participants: Participants = {}
    local scores: { [Player]: number? }?
    local scoreRange = { Min = 0, Max = math.huge }

    local config: MinigameConstants.SessionConfig =
        TableUtil.overwrite(MinigameUtil.getsessionConfig(minigameName), MinigameUtil.getSessionConfigFromQueueStation(queueStation))

    local defaultScore: number?
    local started: boolean = false
    local startedAtTick: number?

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
    function minigameSession:GetMaid()
        return maid
    end

    function minigameSession:GetMinigameName()
        return minigameName
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
        -- RETURN: Unsuccessful teleport
        local didTeleport, _characterCFrame, characterPivotedSignal = ZoneService.teleportPlayerToZone(player, zone, {
            TravelMethod = ZoneConstants.TravelMethod.JoinedMinigame,
        })
        if not didTeleport then
            return
        end

        -- Wait for character to be pivoted
        characterPivotedSignal:Wait()

        table.insert(participants, player)
        minigameSession.ParticipantAdded:Fire(player)
        minigameSession:RelayToOtherParticipants(player, "MinigameParticipantAdded", player)

        Output.doDebug(MinigameConstants.DoDebug, ("%s joined minigame (%s)"):format(player.Name, id))

        Remotes.fireClient(
            player,
            "MinigameJoined",
            id,
            minigameName,
            { Name = stateMachine:GetState(), Data = stateMachine:GetData() },
            minigameSession:GetParticipants(),
            isMultiplayer
        )

        MinigameSession.ParticipantedAdded:Fire(minigameSession, player)

        maid:GiveTask(player.Character.Humanoid.Died:Connect(function()
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

            Output.doDebug(MinigameConstants.DoDebug, ("%s left minigame (%s)"):format(player.Name, id))

            if TableUtil.shallowEquals(zone, ZoneService.getPlayerMinigame(player)) then
                ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerRoom(player), {
                    TravelMethod = ZoneConstants.TravelMethod.LeftMinigame,
                })
            end
        end

        minigameSession.ParticipantRemoved:Fire(player, stillInGame)
        minigameSession:RelayToOtherParticipants(player, "MinigameParticipantRemoved", player, participants)

        local remainingParticipants = #participants
        if remainingParticipants == 0 then
            Output.doDebug(MinigameConstants.DoDebug, ("Minigame session ended (%s)"):format(id))
            maid:Destroy()
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

    function minigameSession:GetParticipantScore(participant: Player)
        return scores[participant]
    end

    function minigameSession:SortScores()
        local sortedScores: MinigameConstants.SortedScores = {}
        local unsorted = TableUtil.deepClone(scores)

        for _ = 1, TableUtil.length(unsorted) do
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

        -- Insert Coins
        for placement, scoreData in pairs(sortedScores) do
            scoreData.CoinsEarned = config.Reward(placement, scoreData.Score, isMultiplayer, #minigameSession:GetParticipants())
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

            Output.doDebug(MinigameConstants.DoDebug, ("Minigame state changed  to %s (%s)"):format(toState, id))

            local data = stateMachine:GetData()
            data.StartTime = Workspace:GetServerTimeNow()

            minigameSession:RelayToParticipants("MinigameStateChanged", { Name = toState, Data = data })
        end)

        if isMultiplayer then
            minigameSession:ChangeState(STATES.Intermission)
        else
            maid:GiveTask(Remotes.bindEventTemp("MinigameStarted", function(player)
                local state = stateMachine:GetState()

                if minigameSession:IsPlayerParticipant(player) and (state == STATES.AwardShow or state == STATES.Nothing) then
                    minigameSession:ChangeState(STATES.Intermission)
                end
            end))

            maid:GiveTask(Remotes.bindEventTemp("MinigameRestarted", function()
                minigameSession:ChangeState(STATES.Nothing)
            end))
        end

        started = true
        startedAtTick = tick()
    end

    -- Returns how long has elapsed since minigame was started
    function minigameSession:GetSessionTime()
        return startedAtTick and (tick() - startedAtTick) or 0
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

            -- Reward + Minigame Records
            for placement, scoreInfo in pairs(sortedScores) do
                local player = scoreInfo.Player
                local score = scoreInfo.Score

                -- Reward
                CurrencyService.injectCoins(player, scoreInfo.CoinsEarned, {
                    OverrideClient = true,
                    InjectCategory = CurrencyUtil.injectCategoryFromMinigame(minigameName, false),
                })

                -- Minigame Records
                do
                    local minigameRecordAddress = ("MinigameRecords.%s"):format(minigameName)

                    -- Highscore
                    local highscoreRecordAddress = ("%s.%s"):format(minigameRecordAddress, "Highscore")
                    local highscore = DataService.get(player, highscoreRecordAddress) or defaultScore
                    if config.HigherScoreWins then
                        if score > highscore then
                            DataService.set(player, highscoreRecordAddress, score)
                            scoreInfo.NewBest = true
                        end
                    else
                        if score < highscore then
                            DataService.set(player, highscoreRecordAddress, score)
                            scoreInfo.NewBest = true
                        end
                    end

                    -- Consecutive Wins
                    if isMultiplayer then
                        local consecutiveWinsRecordAddress = ("%s.%s"):format(minigameRecordAddress, "ConsecutiveWins")
                        local didWin = placement == 1
                        local didWinAgainstOthers = #sortedScores > 1

                        -- Reset if not winner. Don't change if we won solo. Add a win if we beat others.
                        local consecutiveWins = (
                            didWin and (DataService.get(player, consecutiveWinsRecordAddress) or 0) + (didWinAgainstOthers and 0 or 1)
                        ) or 0

                        DataService.set(player, consecutiveWinsRecordAddress, consecutiveWins)
                        scoreInfo.ConsecutiveWins = consecutiveWins
                    end
                end
            end

            -- Relay to client
            stateMachine:GetData().Scores = sortedScores

            -- Relay to server
            MinigameSession.MinigameFinished:Fire(minigameSession, sortedScores)

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
        maid:GiveTask(Remotes.bindEventTemp("MinigameExited", function(player)
            Output.doDebug(MinigameConstants.DoDebug, ("%s requested minigame exit (%s)"):format(player.Name, id))
            minigameSession:RemoveParticipant(player)
        end))

        maid:GiveTask(Remotes.bindEventTemp("MinigameGameplayExited", function(player)
            if not minigameSession:IsPlayerParticipant(player) then
                return
            end

            Output.doDebug(MinigameConstants.DoDebug, ("%s requested minigame gameplay exited(%s)"):format(player.Name, id))
            if isMultiplayer then
                minigameSession:RemoveParticipant(player)
            else
                minigameSession:ChangeState(STATES.AwardShow)
            end
        end))

        maid:GiveTask(ZoneService.ZoneChanged:Connect(function(player)
            minigameSession:RemoveParticipant(player)
        end))

        maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
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
