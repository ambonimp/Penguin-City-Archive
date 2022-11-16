local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local PetsService = require(Paths.Server.Pets.PetsService)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local PetUtils = require(Paths.Shared.Pets.PetUtils)

return function(_context, players: { Player }, petType: string, petVariant: string, petRarity: string, amount: number)
    local petData: PetConstants.PetData = {
        PetTuple = PetUtils.petTuple(petType, petVariant, petRarity),
        Name = "Added Pet",
        BirthServerTime = Workspace:GetServerTimeNow(),
    }

    local output = ""
    for _, player in pairs(players) do
        for _ = 1, amount do
            PetsService.addPet(player, petData)
        end

        output ..= (" > %s +%d %s %s (%s)\n"):format(player.Name, amount, petVariant, petType, petRarity)
    end

    return output
end
