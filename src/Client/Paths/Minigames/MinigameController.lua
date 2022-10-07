--[[
    This is the main hub where a player requests to start/stop a minigame, and gets permission from the server.
]]
local MinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Assume = require(Paths.Shared.Assume)
local Output = require(Paths.Shared.Output)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

type MinigameController = {
    startMinigame: (minigamesDirectory: Folder, () -> MinigameConstants.PlayRequest, ...any) -> nil,
    stopMinigame: (...any) -> nil,
    [any]: any,
}

local currentSession: MinigameConstants.Session | nil
local minigameToController: { [string]: MinigameController } = {
    [MinigameConstants.Minigames.Pizza] = require(Paths.Client.Minigames.Pizza.PizzaMinigameController),
}
local minigamesDirectory = game.Workspace:WaitForChild("Minigames")

-- Returns Assume
function MinigameController.play(minigame: string)
    Output.doDebug(MinigameConstants.DoDebug, "play", minigame)

    -- ERROR: No linked controller
    local minigameController = MinigameController.getControllerFromMinigame(minigame)
    if not minigameController then
        error(("No serviced linked to minigame %q"):format(minigame))
    end

    -- ERROR: Bad zone
    local zoneId = ZoneConstants.ZoneId.Minigame[minigame]
    if not zoneId then
        error(("Could not get ZoneId from minigame %q"):format(minigame))
    end
    local minigameZone = ZoneUtil.zone(ZoneConstants.ZoneType.Minigame, zoneId)

    -- RETURN ERROR: Already playing!
    if currentSession then
        return { Error = ("Client is already playing %s"):format(currentSession.Minigame) }
    end

    -- Assume server response
    local requestAssume = Assume.new(function()
        local playRequest: MinigameConstants.PlayRequest, teleportBuffer: number? =
            Remotes.invokeServer("RequestToPlayMinigame", minigame, game.Workspace:GetServerTimeNow())
        Output.doDebug(MinigameConstants.DoDebug, ".play Assume", playRequest, teleportBuffer)
        return playRequest, teleportBuffer
    end)
    requestAssume:Check(function(playRequest: MinigameConstants.PlayRequest, _teleportBuffer: number?)
        return playRequest and playRequest.Session and true or false
    end)
    requestAssume:Then(function(playRequest: MinigameConstants.PlayRequest)
        currentSession = playRequest.Session
    end)
    requestAssume:Run(function()
        task.spawn(function()
            ZoneController.transitionToZone(minigameZone, function()
                -- Wait for Response
                local _playRequest, teleportBuffer = requestAssume:Await()
                if teleportBuffer then
                    -- Wait for teleport
                    local validationFinishedOffset = requestAssume:GetValidationFinishTimeframe()
                    task.wait(math.max(0, teleportBuffer - validationFinishedOffset))

                    -- Start Minigame
                    minigameController.startMinigame(minigamesDirectory, MinigameController.stopPlaying)
                end
            end, function()
                local playRequest: MinigameConstants.PlayRequest, _teleportBuffer: number? = requestAssume:Await()
                return playRequest and playRequest.Session and true or false
            end)
        end)
    end)

    return requestAssume
end

function MinigameController.getSession()
    return currentSession
end

function MinigameController.getControllerFromMinigame(minigame: string)
    return minigameToController[minigame]
end

-- Returns Assume
function MinigameController.stopPlaying(): MinigameConstants.PlayRequest
    Output.doDebug(MinigameConstants.DoDebug, "stopPlaying")

    -- WARN: Not playing!
    if not currentSession then
        return { Error = "Cannot stop playing for Client; they weren't playing in the first place!" }
    end

    -- Assume server response
    local guessedZone = ZoneController.getCurrentRoomZone()
    local requestAssume = Assume.new(function()
        local playRequest: MinigameConstants.PlayRequest, roomZoneId: string?, teleportBuffer: number? =
            Remotes.invokeServer("RequestToStopPlaying", game.Workspace:GetServerTimeNow())
        Output.doDebug(MinigameConstants.DoDebug, ".play Assume", playRequest, teleportBuffer)
        local zone = roomZoneId and ZoneUtil.zone(ZoneConstants.ZoneType.Room, roomZoneId) or nil
        return playRequest, zone, teleportBuffer
    end)
    requestAssume:Check(function(playRequest: MinigameConstants.PlayRequest, _zone: ZoneConstants.Zone?, _teleportBuffer: number?)
        return playRequest and playRequest.Session and true or false
    end)
    requestAssume:Run(function()
        task.spawn(function()
            ZoneController.transitionToZone(guessedZone, function()
                -- Stop Minigame
                local oldSession = currentSession
                local minigameController = MinigameController.getControllerFromMinigame(oldSession.Minigame)
                minigameController.stopMinigame()

                -- Wait for Response
                local _playRequest, _actualZone, teleportBuffer: number = requestAssume:Await()
                if teleportBuffer then
                    -- Wait for teleport
                    local validationFinishedOffset = requestAssume:GetValidationFinishTimeframe()
                    task.wait(math.max(0, teleportBuffer - validationFinishedOffset))
                end
            end, function()
                local playRequest: MinigameConstants.PlayRequest, _zone: ZoneConstants.Zone?, _teleportBuffer: number? =
                    requestAssume:Await()
                return playRequest and playRequest.Session and true or false
            end)
        end)
    end)

    return requestAssume
end

return MinigameController
