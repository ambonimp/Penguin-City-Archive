local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PetService = require(Paths.Server.Pets.PetService)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        output ..= (" > %s:\n"):format(player.Name)

        local petDatas = PetService.getPets(player)
        for _, petData in pairs(petDatas) do
            output ..= ("    %s %s (%s)\n"):format(petData.PetTuple.PetVariant, petData.PetTuple.PetType, petData.PetTuple.PetRarity)
        end
    end

    return output
end
