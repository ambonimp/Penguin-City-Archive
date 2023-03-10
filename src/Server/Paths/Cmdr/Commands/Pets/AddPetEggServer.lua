local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PetService = require(Paths.Server.Pets.PetService)

return function(_context, players: { Player }, petEggName: string, hatchTime: number, amount: number)
    local output = ""
    for _, player in pairs(players) do
        for _ = 1, amount do
            PetService.addPetEgg(player, petEggName, hatchTime)
        end

        output ..= (" > %s +%d %s Pet Eggs\n"):format(player.Name, amount, petEggName)
    end

    return output
end
