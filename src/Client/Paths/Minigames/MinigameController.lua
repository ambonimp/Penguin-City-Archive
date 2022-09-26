local MinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Assume = require(Paths.Shared.Assume)
local Output = require(Paths.Shared.Output)

type MinigameController = {
    startMinigame: (...any) -> nil,
    stopMinigame: (...any) -> nil,
}

local currentSession: MinigameConstants.Session | nil
local minigameToController: { [string]: MinigameController } = {
    [MinigameConstants.Minigames.Pizza] = require(Paths.Client.Minigames.Pizza.PizzaMinigameController),
}

-- Yields Server
function MinigameController.play(minigame: string)
    Output.doDebug(MinigameConstants.DoDebug, "MinigameController.play", minigame)

    -- ERROR: No linked controller
    local minigameController = MinigameController.getControllerFromMinigame(minigame)
    if not minigameController then
        error(("No serviced linked to minigame %q"):format(minigame))
    end

    -- RETURN ERROR: Already playing!
    if currentSession then
        return { Error = ("Client is already playing %s"):format(currentSession.Minigame) }
    end

    -- Assume server response
    local assume = Assume.new(function()
        local serverResponse = Remotes.invokeServer("RequestToPlayMinigame", minigame)
        Output.doDebug(MinigameConstants.DoDebug, ".play Assume", serverResponse)
        return serverResponse
    end)
    assume:Check(function(scopeServerResponse: MinigameConstants.PlayRequest)
        return scopeServerResponse.Session and true or false
    end)
    assume:Then(function(scopeServerResponse: MinigameConstants.PlayRequest)
        currentSession = scopeServerResponse.Session
    end)
    assume:Else(function(_scopeServerResponse: MinigameConstants.PlayRequest)
        minigameController.stopMinigame()
    end)
    assume:Run(function()
        minigameController.startMinigame()
    end)

    local serverResponse = assume:Await()
    return serverResponse
end

function MinigameController.getSession()
    return currentSession
end

function MinigameController.getControllerFromMinigame(minigame: string)
    return minigameToController[minigame]
end

function MinigameController.stopPlaying(): MinigameConstants.PlayRequest
    Output.doDebug(MinigameConstants.DoDebug, "MinigameController.stopPlaying")

    -- WARN: Not playing!
    if not currentSession then
        return { Error = "Cannot stop playing for Client; they weren't playing in the first place!" }
    end

    -- Async Stop Minigame on server (Either successful, or wasn't playing in the first place)
    task.spawn(function()
        local _serverResponse = Remotes.invokeServer("RequestToStopPlaying")
    end)

    -- Stop Minigame
    local oldSession = currentSession
    local minigameController = MinigameController.getControllerFromMinigame(oldSession.Minigame)
    minigameController.stopMinigame()

    -- Clear Cache
    currentSession = nil

    return { Session = oldSession }
end

return MinigameController
