local MinigameSession = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)
local Signal = require(Paths.Shared.Signal)
local Remotes = require(Paths.Shared.Remotes)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local StateMachine = require(Paths.Shared.StateMachine)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)

type Participants = { Player }

local STATES = MinigameConstants.States

function MinigameSession.new(minigameName: string, id: string, startingParticipants: Participants)
    local minigameSession = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local stateMachine = StateMachine.new(TableUtil.getKeys(STATES), STATES.Nothing)

    local zone: ZoneConstants.Zone = ZoneUtil.zone(ZoneConstants.ZoneType.Minigame, id)
    local map: Model = ServerStorage.Minigames[minigameName].Map:Clone()
    maid:GiveTask(ZoneService.createZone(zone, { map }, map.PrimaryPart:Clone()))

    local participants: Participants = {}
    local isMultiplayer: boolean = #startingParticipants > 1

    local config: MinigameConstants.SessionConfig = MinigameUtil.getSessionConfigs(minigameName)

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
    function minigameSession:GetStateMachine()
        return stateMachine
    end

    function minigameSession:GetMap(): Model
        return map
    end

    function minigameSession:GetMaid()
        return maid
    end

    function minigameSession:isMultiplayer(): boolean
        return isMultiplayer
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
        print("TOCLENT", stateMachine:GetData())
        Remotes.fireClient(
            player,
            "MinigameJoined",
            id,
            minigameName,
            { Name = stateMachine:GetState(), Data = stateMachine:GetData() },
            getOtherParticipants(player),
            isMultiplayer
        )
    end

    function minigameSession:RemoveParticipant(player)
        -- RETURN: Player is not a participant
        if not minigameSession:IsPlayerParticipant(player) then
            return
        end

        -- Player didn't leave the game
        if player.Parent == Players then
            Remotes.fireClient(player, "MinigameExited", id)

            if TableUtil.shallowEquals(zone, ZoneService.getPlayerMinigame(player)) then
                ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerRoom(player))
            end
        end

        local remainingParticipants = #participants
        if remainingParticipants == 0 then
            maid:Destroy()
        else
            if remainingParticipants == config.MinParticipants - 1 and config.StrictlyEnforcePlayerCount then
                local state = stateMachine:GetState()
                if state == STATES.Core or state == STATES.CoreCountdown then
                    stateMachine:Push(STATES.Intermission) -- This will then go to WaitingForPlayers
                end
            end

            table.remove(participants, table.find(participants, player))
            minigameSession.ParticipantRemoved:Fire(player)
            minigameSession:RelayToOtherParticipants(player, "MinigameParticipantRemoved", player, participants)
        end
    end

    function minigameSession:GetParticipants(): Participants
        return participants
    end

    function minigameSession:IsAcceptingNewParticipants()
        local state = stateMachine:GetState()
        return isMultiplayer and (state == STATES.Intermission or state == STATES.AwardShow) and #participants < config.MaxParticipants
    end

    function minigameSession:CountdownSync(length: number): boolean
        local currentState = stateMachine:GetState()

        while currentState == stateMachine:GetState() and length > 0 do
            length -= 1
            task.wait(1)
        end

        return length == 0
    end

    function minigameSession:Start() -- Ideally, all events have been connected and everything is ready to go when you run this
        stateMachine:Push(STATES.Intermission)
        for _, player in pairs(startingParticipants) do
            minigameSession:AddParticipant(player)
        end

        if not isMultiplayer then
            maid:GiveTask(Remotes.bindEventTemp("MinigameRestarted", function(player)
                if minigameSession:IsPlayerParticipant(player) and stateMachine:GetState() == STATES.AwardShow then
                    stateMachine:Push(STATES.Intermission)
                end
            end))
        end
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    -- Register state
    do
        stateMachine:RegisterStateCallbacks(STATES.WaitingForPlayers, function()
            minigameSession.WaitingForPlayers = minigameSession.ParticipantAdded:Connect(function()
                if #participants >= config.MinParticipants then
                    stateMachine:Push(STATES.Intermission)
                end
            end)
        end)

        stateMachine:RegisterStateCallbacks(STATES.Intermission, function()
            if isMultiplayer then
                -- RETURN: Waiting for more players
                if #participants < config.MinParticipants then
                    stateMachine:Push(STATES.WaitingForPlayers)
                    return
                end

                -- RETURN: This is no longer the state
                if not minigameSession:CountdownSync(config.IntermissionLength) then
                    return
                end
            end

            if config.CoreCountdown then
                stateMachine:Push(STATES.CoreCountdown)
            else
                stateMachine:Push(STATES.Core)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.CoreCountdown, function()
            if minigameSession:CountdownSync(4) then
                stateMachine:Push(STATES.Core)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.Core, function()
            if minigameSession:CountdownSync(config.CoreLength) then
                stateMachine:Push(STATES.AwardShow)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.AwardShow, function()
            if isMultiplayer then
                minigameSession:CountdownSync(config.AwardShowLength)
                stateMachine:Push(STATES.Intermission)
            end
        end)

        stateMachine:RegisterGlobalCallback(function(_, toState)
            warn("SERVER", toState)

            local data = stateMachine:GetData()
            data.StartTime = Workspace:GetServerTimeNow()

            minigameSession:RelayToParticipants("MinigameStateChanged", { Name = toState, data })
        end)
    end

    -- Leaving
    do
        maid:GiveTask(Remotes.bindEventTemp("MinigameExited", function(player)
            minigameSession:RemoveParticipant(player)
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

return MinigameSession
