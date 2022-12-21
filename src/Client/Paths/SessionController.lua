--[[
    A basic `Session` on the client, that doesn't get informed about nearly as much as our server scope
]]
local SessionController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Session = require(Paths.Shared.Session)

local session = Session.new(Players.LocalPlayer)

function SessionController.getSession()
    return session
end

return SessionController
