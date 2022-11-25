local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

local function stringsGetter()
    return TableUtil.getKeys(PetConstants.PetEggs)
end

local function stringToObject(petEgg: string)
    return petEgg
end

return function(registry)
    registry:RegisterType("petEgg", CmdrUtil.createTypeDefinition("petEgg", stringsGetter, stringToObject))
end
