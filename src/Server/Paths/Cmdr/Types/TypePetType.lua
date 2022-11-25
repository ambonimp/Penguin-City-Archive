local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

local function stringsGetter()
    return TableUtil.toArray(PetConstants.PetTypes)
end

local function stringToObject(petType: string)
    return petType
end

return function(registry)
    registry:RegisterType("petType", CmdrUtil.createTypeDefinition("petType", stringsGetter, stringToObject))
end
