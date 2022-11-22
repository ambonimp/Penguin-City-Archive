local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PetService = require(Paths.Server.Pets.PetService)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        output ..= (" > %s:\n"):format(player.Name)

        local allHatchTimes = PetService.getHatchTimes(player)
        for petEggName, hatchTimes in pairs(allHatchTimes) do
            for _, hatchTime in pairs(hatchTimes) do
                output ..= ("    %s Pet Egg (%ds)\n"):format(petEggName, hatchTime)
            end
        end
    end

    return output
end
