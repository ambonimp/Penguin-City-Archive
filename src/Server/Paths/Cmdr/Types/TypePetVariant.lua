local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local PetUtils = require(ReplicatedStorage.Shared.Pets.PetUtils)

return function(registry)
    -- We have to create a uniqe petVariant type for each petType
    for petType, petVariants in pairs(PetConstants.PetVariants) do
        local function stringsGetter()
            return TableUtil.getKeys(petVariants)
        end

        local function stringToObject(petVariant: string)
            return petVariant
        end

        local typeName = PetUtils.getPetVariantCmdrTypeName(petType)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
