local UnitTestingService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local UnitTester = require(Paths.Shared.UnitTester)

task.spawn(function()
    UnitTester.Run({ Paths.Server, Paths.Shared })
end)

return UnitTestingService
