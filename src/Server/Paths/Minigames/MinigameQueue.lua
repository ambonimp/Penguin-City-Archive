local MinigameQueue = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Maid = require(Paths.Packages.maid)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)

function MinigameQueue.new(minigameName: string)
    local queue = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local maid = Maid.new()

    local sessionConfig = MinigameUtil.getSessionConfigs(minigameName)

    local participants = {}
    local minigameStartThread: thread?

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function onParticipantRemoved(player: Player)
        -- RETURN: Player isn't in the queue
        if not participants[player] then
            return
        end

        table.remove(participants, table.find(participants, player))
        if #participants < sessionConfig.MinParticipants then
            task.cancel(minigameStartThread)
            minigameStartThread = nil
        end

        Remotes.fireClient(player, "MinigameQueueExited")
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function queue:AddParticipant(player: Player)
        table.insert(participants, player)

        if #participants == sessionConfig.MinParticipants then
            minigameStartThread = task.delay(MinigameConstants.MaximumSufficientlyFilledQueueLength, function()
                maid:Destroy()
            end)
        elseif #participants == sessionConfig.MaxParticipants then
            task.spawn(minigameStartThread)
        end

        Remotes.fireClient(player, "MinigameQueueJoined", minigameName)
    end

    function queue:GetParticipants()
        return participants
    end

    function queue:IsParticipant(player: Player): boolean
        return table.find(participants, player) ~= nil
    end

    function queue:GetMaid()
        return maid
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    maid:GiveTask(Players.PlayerRemoving:Connect(onParticipantRemoved))
    maid:GiveTask(Remotes.bindEventTemp("MinigameQueueExited", onParticipantRemoved))
    maid:GiveTask(function()
        Remotes.fireClients(participants, "MinigameQueueExited")
    end)

    return queue
end

do
    Remotes.declareEvent("MinigameQueueJoined")
    Remotes.declareEvent("MinigameQueueExited")
end

return MinigameQueue
