local MinigameQueue = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Janitor = require(Paths.Packages.janitor)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local QueueStationService = require(Paths.Server.Minigames.QueueStationService)

function MinigameQueue.new(minigameName: string, station: Model?)
    local queue = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local janitor = Janitor.new()

    local sessionConfig =
        TableUtil.overwrite(MinigameUtil.getsessionConfig(minigameName), MinigameUtil.getSessionConfigFromQueueStation(station))

    local participants: { Player } = {}
    local minigameStartThread: thread?

    local statusBoard: BasePart? = if station then QueueStationService.resetStatusBoard(station, sessionConfig) else nil
    local countdown: number?

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------

    local function updateStatusBoard()
        if statusBoard then
            QueueStationService.updateStatus(statusBoard, sessionConfig, #participants, countdown)
        end
    end

    local function onParticipantRemoved(player: Player, closing: true?)
        -- RETURN: Player isn't in the queue
        if not table.find(participants, player) then
            return
        end

        if not closing then
            table.remove(participants, table.find(participants, player))
            if #participants <= sessionConfig.MinParticipants and minigameStartThread then
                task.cancel(minigameStartThread)
                minigameStartThread = nil
                countdown = nil
            end
        end

        updateStatusBoard()
        Remotes.fireClient(player, "MinigameQueueExited")
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function queue:AddParticipant(player: Player)
        table.insert(participants, player)

        if #participants == sessionConfig.MinParticipants then
            minigameStartThread = task.spawn(function()
                countdown = MinigameConstants.MaximumSufficientlyFilledQueueLength
                while countdown > 0 do
                    countdown -= 1
                    updateStatusBoard()

                    task.wait(1)
                end

                janitor:Destroy()
            end)
        elseif #participants == sessionConfig.MaxParticipants then
            countdown = 0
        end

        updateStatusBoard()
        Remotes.fireClient(player, "MinigameQueueJoined", minigameName)
    end

    function queue:GetParticipants()
        return participants
    end

    function queue:IsParticipant(player: Player): boolean
        return table.find(participants, player) ~= nil
    end

    function queue:GetJanitor()
        return janitor
    end

    function queue:GetStation(): Model
        return station
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    janitor:Add(Players.PlayerRemoving:Connect(onParticipantRemoved :: (Player) -> ()))
    janitor:Add(Remotes.bindEventTemp("MinigameQueueExited", onParticipantRemoved))
    janitor:Add(function()
        for _, participant in pairs(participants) do
            onParticipantRemoved(participant, true)
        end

        if statusBoard then
            QueueStationService.resetStatusBoard(station, sessionConfig)
        end
    end)

    return queue
end

do
    Remotes.declareEvent("MinigameQueueJoined")
    Remotes.declareEvent("MinigameQueueExited")
end

return MinigameQueue
