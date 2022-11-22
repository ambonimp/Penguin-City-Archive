local SessionService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Session = require(Paths.Shared.Session)
local PlayerService = require(Paths.Server.PlayerService)

local sessionByPlayer: { [Player]: typeof(Session.new(game.Players:GetPlayers()[1])) } = {}

function SessionService.loadPlayer(player: Player)
    sessionByPlayer[player] = Session.new(player)
    PlayerService.getPlayerMaid(player):GiveTask(function()
        sessionByPlayer[player] = nil
    end)
end

function SessionService.getSession(player: Player)
    return sessionByPlayer[player]
end

return SessionService
