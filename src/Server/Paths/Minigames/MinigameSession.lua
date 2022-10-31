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

local STATES = MinigameConstants.States

function MinigameSession.new(minigameName: string, id: string, startingParticipants: { Player })
    local minigameSession = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local stateMachine = StateMachine.new(TableUtil.getKeys(STATES), STATES.Nothing)

    local zone: ZoneConstants.Zone = ZoneUtil.zone(ZoneConstants.ZoneType.Minigame, id)
    local map: Model = ServerStorage.Minigames[minigameName].Map:Clone()
    maid:GiveTask(ZoneService.createZone(zone, { map }, map.PrimaryPart))

    local participants: { Player } = {}
    local isMultiplayer: boolean = #startingParticipants == 1

    local config: MinigameConstants.SessionConfig = require(Paths.Shared.Minigames[minigameName][minigameName .. "Constants"]).SessionConfig

    -------------------------------------------------------------------------------
    -- PUBLIC MEMBERS
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded = Signal.new()
    minigameSession.ParticipantRemoved = Signal.new()

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function minigameSession:GetStateMachine()
        return stateMachine
    end

    function minigameSession:GeMap(): Model
        return map
    end

    function minigameSession:GetMaid()
        return Maid
    end

    function minigameSession:RelayToParticipants(eventName: string, ...: any)
        Remotes.fireClients(participants, eventName, ...)
    end

    function minigameSession:RelayToOtherParticipants(exception: Player, eventName: string, ...: any)
        for _, participant in pairs(participants) do
            if participant ~= exception then
                Remotes.fireClient(participant, eventName, ...)
            end
        end
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

        table.insert(participants, player)
        minigameSession.ParticipantAdded:Fire(player)

        minigameSession:RelayToOtherParticipants(player, "MinigameParticipantAdded", player)
        Remotes.fireClient(player, "MinigameJoined", id, { Name = stateMachine:GetState(), stateMachine:GetData().StartTime })
    end

    function MinigameSession:RemoveParticipant(player)
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
            minigameSession:RelayToOtherParticipants(player, "MinigameParticipantRemoved", player)
        end
    end

    function minigameSession:IsAcceptingNewParticipants()
        local state = stateMachine:GetState()
        return isMultiplayer and (state == STATES.Intermission or state == STATES.AwardShow) and #participants < config.MaxParticipants
    end

    function MinigameSession.countdown(length: number): boolean
        local currentState = stateMachine:GetState()

        while currentState == stateMachine:GetState() and length > 0 do
            length -= 1
            task.wait(1)
        end

        return length == 0
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
                if #participants < config.MinParticipants then
                    stateMachine:Push(STATES.WaitingForPlayers)
                end

                -- RETURN: This is no longer the state
                if not minigameSession:Countdown(config.IntermissionLength) then
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
            if minigameSession:Countdown(4) then
                stateMachine:Push(STATES.Core)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.Core, function()
            if minigameSession:Countdown(config.CoreLength) then
                stateMachine:Push(STATES.AwardShow)
            end
        end)

        stateMachine:RegisterStateCallbacks(STATES.AwardShow, function()
            if isMultiplayer then
                minigameSession:Countdown(config.AwardShowLength)
                stateMachine:Push(STATES.Intermission)
            end
        end)

        stateMachine:RegisterGlobalCallback(function(_, toState, data)
            data.StartTime = Workspace:GetServerTimeNow()
            minigameSession:RelayToParticipants("MinigameStateChanged", { Name = toState, StartTime = data.StartTime })
        end)
    end

    -- Start
    do
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
