local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
    return TableUtil.toArray(MinigameConstants.Minigames)
end

local function stringToObject(minigameString: string)
    warn(minigameString)
    return minigameString
end

return function(registry)
    registry:RegisterType("minigame", CmdrUtil.createTypeDefinition("minigame", stringsGetter, stringToObject))
end
