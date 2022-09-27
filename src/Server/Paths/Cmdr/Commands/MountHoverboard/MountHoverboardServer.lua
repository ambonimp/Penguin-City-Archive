local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local VehicleService = require(Paths.Server.VehicleService)

return function(_context, players: { Player })
    for _, player in pairs(players) do
        VehicleService.mountVehicle(player, "Hoverboard")
    end

    return "Mounted Players"
end
