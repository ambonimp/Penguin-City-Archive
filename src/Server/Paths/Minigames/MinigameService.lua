--[[
    Tracks what minigames players are playing
    ]]
local MinigameService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Modules = Paths.Modules
local Remotes = require(Modules.Remotes)
local TypeUtil = require(Modules.Utils.TypeUtil)
local TableUtil = require(Modules.Utils.TableUtil)
local MinigameConstants = require(Modules.Minigames.MinigameConstants)

type Session = {
    Minigame: string,
    Id: number,
}

type MinigameService = {
    startMinigame: (player: Player, ...any) -> nil,
    stopMinigame: (player: Player, ...any) -> nil,
}

local playSessions: { [Player]: Session } = {}
local sessionIdCounter = 0
local minigameToService: { [string]: MinigameService } = {
    [MinigameConstants.Minigames.Pizza] = require(Modules.Minigames.Pizza.PizzaMinigameService),
}

--[[
    - Returns a unique session ID if permission granted
    - Returns nil otherwise (e.g., already playing a minigame)
]]
function MinigameService.requestToPlay(player: Player, minigame: string): Session | nil
    -- ERROR: No linked service
    local minigameService = MinigameService.getServiceFromMinigame(minigame)
    if not minigameService then
        error(("No serviced linked to minigame %q"):format(minigame))
    end

    if playSessions[player] then
        return
    end

    -- Create Session
    local sessionId = sessionIdCounter
    sessionIdCounter += 1

    local session: Session = {
        Minigame = minigame,
        Id = sessionId,
    }
    playSessions[player] = session

    -- Start Minigame
    minigameService.startMinigame(player)

    return session
end

function MinigameService.getSession(player: Player): Session | nil
    return playSessions[player]
end

function MinigameService.getServiceFromMinigame(minigame: string)
    return minigameToService[minigame]
end

-- - Returns true if a minigame session was stopped from this call
function MinigameService.stopPlaying(player: Player)
    -- WARN: Not playing!
    if not playSessions[player] then
        warn("Cannot stop playing for %s; they weren't playing in the first place!")
        return false
    end

    -- Stop Minigame
    local session = MinigameService.getSession(player)
    local minigameService = MinigameService.getServiceFromMinigame(session.Minigame)
    minigameService.stopMinigame(player)

    -- Clear Session
    playSessions[player] = nil

    return true
end

-- Clear Cache
do
    Players.PlayerRemoving:Connect(function(player)
        -- RETURN: No session!
        local currentSession = MinigameService.getSession(player)
        if not currentSession then
            return
        end

        MinigameService.stopPlaying(player)
    end)
end

-- Setup Communication
do
    Remotes.bindFunctions({
        RequestToPlayMinigame = function(player: Player, dirtyMinigame: any)
            -- Verify + Clean parameters
            local minigame = TypeUtil.toString(dirtyMinigame)
            if not (minigame and TableUtil.find(MinigameConstants.Minigames, minigame)) then
                return
            end

            return MinigameService.requestToPlay(player, minigame)
        end,

        RequestToStopPlaying = function(player: Player)
            return MinigameService.stopPlaying(player)
        end,
    })
end

return MinigameService
