local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CmdrService = require(Paths.Server.Cmdr.CmdrService)

return function(context)
    local player: Player = context.Executor
    CmdrService.invokeClientLogic(player, "ViewImages")

    return "Viewing Images"
end
