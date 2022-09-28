local UnitTestingController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UnitTester = require(Paths.Shared.UnitTester)

task.spawn(function()
    UnitTester.Run(Paths.Client)
end)

return UnitTestingController
