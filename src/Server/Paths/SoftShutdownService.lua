--[[
	This system lets you shut down servers without losing a lot of players.
	When game.OnClose is called, the script teleports everyone in the server
	into a reserved server.
	
	When the reserved servers start up, they wait a few seconds, and then
	send everyone back into the main place.
	
	I added task.wait() in a couple of places because if you don't, everyone will spawn into
	their own servers with only 1 player.
--]]

local SoftShutdownService = {}

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)

local placeId = game.PlaceId

if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
    -- this is a reserved server without a VIP server owner
    local message = Instance.new("Message")
    message.Text = "Teleporting back in a moment!"
    message.Parent = workspace

    Remotes.fireAllClients("LeavingViaSoftShutdown")

    local timeout = 5

    Players.PlayerAdded:Connect(function(player)
        task.wait(timeout)
        timeout /= 2
        TeleportService:Teleport(placeId, player)
    end)

    for _, player in pairs(Players:GetPlayers()) do
        TeleportService:Teleport(placeId, player)
        task.wait(timeout)
        timeout /= 2
    end
else
    game:BindToClose(function()
        if #Players:GetPlayers() == 0 then
            return
        end

        if game.JobId == "" then
            -- Offline
            return
        end

        Remotes.fireAllClients("ReEnteringViaSoftShutdown")

        task.wait(2)
        local reservedServerCode = TeleportService:ReserveServer(game.PlaceId)

        for _, player in pairs(Players:GetPlayers()) do
            TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, { player })
        end
        Players.PlayerAdded:Connect(function(player)
            TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, { player })
        end)

        while #Players:GetPlayers() > 0 do
            task.wait(1)
        end
    end)
end

Remotes.declareEvent("LeavingViaSoftShutdown")
Remotes.declareEvent("ReEnteringViaSoftShutdown")

return SoftShutdownService
