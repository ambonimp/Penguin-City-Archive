local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

return function(registry)
    -- We have to create a uniqe stampId type for each stampType
    for _, stampType in pairs(Stamps.StampTypes) do
        local stampIds: { string } = {}
        for _, stamp in pairs(StampUtil.getStampsFromType(stampType)) do
            table.insert(stampIds, stamp.Id)
        end

        local function stringsGetter()
            return stampIds
        end

        local function stringToObject(stampId: string)
            return stampId
        end

        local typeName = StampUtil.getStampIdCmdrTypeName(stampType)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
