local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

local function stringsGetter()
    return TableUtil.toArray(PetConstants.PetRarities)
end

local function stringToObject(petRarity: string)
    return petRarity
end

return function(registry)
    registry:RegisterType("petRarity", CmdrUtil.createTypeDefinition("petRarity", stringsGetter, stringToObject))
end
