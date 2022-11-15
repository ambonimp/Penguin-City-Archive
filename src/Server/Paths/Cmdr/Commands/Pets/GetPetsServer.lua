local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PetsService = require(Paths.Server.Pets.PetsService)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        output ..= (" > %s:\n"):format(player.Name)

        local petDatas = PetsService.getPets(player)
        for _, petData in pairs(petDatas) do
            output ..= ("    %s %s (%s)"):format(petData.PetTuple.PetVariant, petData.PetTuple.PetType, petData.PetTuple.PetRarity)
        end
    end

    return output
end
