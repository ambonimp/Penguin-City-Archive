local MinigameQueue = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Maid = require(Paths.Packages.maid)

local WAIT_LENGTH = 30

function MinigameQueue.new(minigameName: string)
    local queue = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local maid = Maid.new()

    local constants = require(Paths.Shared.Minigames[minigameName][minigameName .. "Contants"])
    local minPlayerCount =
        assert(constants.MinPlayerCount, ("%s minigame constants does not have a MinPlayerCount member"):format(minigameName))
    local maxPlayerCount =
        assert(constants.MaxPlayerCount, ("%s minigame constants does not have a MaxPlayerCount member"):format(minigameName))

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
        if #participants < minPlayerCount then
            task.cancel(minigameStartThread)
            minigameStartThread = nil
        end
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function queue:AddParticipant(player: Player)
        table.insert(participants, player)

        if #participants == minPlayerCount then
            minigameStartThread = task.delay(WAIT_LENGTH, function()
                maid:Destroy()
            end)
        elseif #participants == maxPlayerCount then
            task.spawn(minigameStartThread)
        end

        Remotes.fireClient(player, "JoinedMinigameQueue")
    end

    function queue:GetParticipants()
        return participants
    end

    function queue:GetMaid()
        return maid
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    maid:GiveTask(Players.PlayerRemoving:Connect(onParticipantRemoved))
    maid:GiveTask(Remotes.bindEventTemp("LeftMinigameQueue", onParticipantRemoved))

    return queue
end

return MinigameQueue
