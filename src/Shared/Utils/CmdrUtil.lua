local CmdrUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupUtil = require(ReplicatedStorage.Shared.Utils.GroupUtil)

function CmdrUtil.IsAdmin(player: Player)
    return GroupUtil.isAdmin(player)
end

return CmdrUtil
