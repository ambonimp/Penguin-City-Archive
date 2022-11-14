local SessionController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Session = require(Paths.Shared.Session)

local session = Session.new(Players.LocalPlayer)

function SessionController.getSession()
    return session
end

return SessionController
