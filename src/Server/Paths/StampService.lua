local StampService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local DataService = require(Paths.Server.Data.DataService)

function StampService.hasStamp(player: Player, stampId: string)
    return DataService.get(player, StampUtil.getStampDataAddress(stampId)) and true or false
end

function StampService.addStamp(player: Player, stampId: string)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp and not StampService.hasStamp(player, stampId) then
        DataService.set(player, StampUtil.getStampDataAddress(stampId), true, "StampUpdated", { StampId = stampId })
        return true
    end
    return false
end

function StampService.revokeStamp(player: Player, stampId: string)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp and StampService.hasStamp(player, stampId) then
        DataService.set(player, StampUtil.getStampDataAddress(stampId), nil, "StampUpdated", { StampId = stampId })
        return true
    end
    return false
end

return StampService
