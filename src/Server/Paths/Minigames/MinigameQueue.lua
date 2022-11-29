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
        TableUtil.merge(MinigameUtil.getsessionConfig(minigameName), MinigameUtil.getSessionConfigFromQueueStation(station))

    local participants = {}
    local minigameStartThread: thread?

    local statusBoard = QueueStationService.resetStatusBoard(station, sessionConfig)
    local countdown: number?

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------

    local function updateStatusBoard()
        if statusBoard then
            QueueStationService.updateStatus(statusBoard, sessionConfig, #participants, countdown)
        end
    end

    local function onParticipantRemoved(player: Player)
        -- RETURN: Player isn't in the queue
        if not participants[player] then
            return
        end

        table.remove(participants, table.find(participants, player))
        if #participants < sessionConfig.MinParticipants then
            task.cancel(minigameStartThread)
            minigameStartThread = nil
            countdown = nil
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

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    janitor:Add(Players.PlayerRemoving:Connect(onParticipantRemoved))
    janitor:Add(Remotes.bindEventTemp("MinigameQueueExited", onParticipantRemoved))
    janitor:Add(function()
        Remotes.fireClients(participants, "MinigameQueueExited")
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
