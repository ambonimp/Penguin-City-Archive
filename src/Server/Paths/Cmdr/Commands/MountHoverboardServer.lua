local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Vehicles = require(Paths.Modules.Vehicles)

return function(_context, players: { Player })
    for _, player in pairs(players) do
        Vehicles.mountVehicle(player, "Hoverboard")
    end

    return "Mounted Players"
end
