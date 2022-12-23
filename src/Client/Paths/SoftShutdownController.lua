local SoftShutdownController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)

local screen = Paths.UI.SoftShutdown
local frame = screen.Main
local background = screen.Background

screen.Enabled = false

Remotes.bindEvents({
    LeavingViaSoftShutdown = function()
        screen.Enabled = true
        background.Visible = true
        frame.Visible = true

        frame.Title.Text = "Restarting Servers for an Update..."
        frame.PleaseWait.Text = "Please wait patiently"
    end,
    ReEnteringViaSoftShutdown = function()
        screen.Enabled = true
        frame.Visible = true
        background.Visible = true

        frame.Title.Text = "Teleporting back in a moment..."
    end,
})

return SoftShutdownController
