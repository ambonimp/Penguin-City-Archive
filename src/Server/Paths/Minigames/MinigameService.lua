--[[
    Tracks what minigames players are playing
    ]]
local MinigameService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Output = require(Paths.Shared.Output)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

type MinigameService = {
    startMinigame: (player: Player, ...any) -> nil,
    stopMinigame: (player: Player, ...any) -> nil,
    developerToLive: ((minigamesDirectory: Folder) -> nil)?, -- Optional method to clean up a minigame from "developer mode" to "live mode"
    [any]: any,
}

local playSessions: { [Player]: MinigameConstants.Session } = {}
local sessionIdCounter = 0
local minigameToService: { [string]: MinigameService } = {
    [MinigameConstants.Minigames.Pizza] = require(Paths.Server.Minigames.Pizza.PizzaMinigameService),
}

function MinigameService.requestToPlay(player: Player, minigame: string): MinigameConstants.PlayRequest
    Output.doDebug(MinigameConstants.DoDebug, "requestToPlay", player)

    -- ERROR: No linked service
    local minigameService = MinigameService.getServiceFromMinigame(minigame)
    if not minigameService then
        error(("No serviced linked to minigame %q"):format(minigame))
    end

    local existingSession = playSessions[player]
    if existingSession then
        local playRequest = { Error = ("%s is already playing %s"):format(player.Name, existingSession.Minigame) }
        Output.doDebug(MinigameConstants.DoDebug, "requestToPlay", playRequest.Error)
        return playRequest
    end

    -- Create MinigameConstants.Session
    local sessionId = sessionIdCounter
    sessionIdCounter += 1

    local session: MinigameConstants.Session = {
        Minigame = minigame,
        Id = sessionId,
    }
    playSessions[player] = session

    -- Start Minigame
    minigameService.startMinigame(player)

    return { Session = session }
end

function MinigameService.getSession(player: Player): MinigameConstants.Session | nil
    return playSessions[player]
end

function MinigameService.getServiceFromMinigame(minigame: string)
    return minigameToService[minigame]
end

function MinigameService.stopPlaying(player: Player): MinigameConstants.PlayRequest
    Output.doDebug(MinigameConstants.DoDebug, "stopPlaying", player)

    -- WARN: Not playing!
    if not playSessions[player] then
        local playRequest = { Error = ("Cannot stop playing for %s; they weren't playing in the first place!"):format(player.Name) }
        Output.doDebug(MinigameConstants.DoDebug, "stopPlaying", playRequest.Error)
        return playRequest
    end

    -- Stop Minigame
    local session = MinigameService.getSession(player)
    local minigameService = MinigameService.getServiceFromMinigame(session.Minigame)
    minigameService.stopMinigame(player)

    -- Clear Cache
    playSessions[player] = nil

    return { Session = session }
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

-- Developer to Live
do
    local minigamesDirectory = game.Workspace:WaitForChild("Minigames")
    for _, minigameService in pairs(minigameToService) do
        minigameService.developerToLive(minigamesDirectory)
    end
end

return MinigameService
