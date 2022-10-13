--[[
    Useful API for interacting with the Penguin City Roblox Group
    ]]
local GroupUtil = {}

local GROUP_ID = 12843903
local RANK_ADMIN = 250
local RANK_TESTER = 50

-- Yields on first call, but Roblox API uses a cache afterwards.
function GroupUtil.getRank(player: Player)
    return player:GetRankInGroup(GROUP_ID)
end

function GroupUtil.isAdmin(player: Player)
    return GroupUtil.getRank(player) >= RANK_ADMIN
end

function GroupUtil.isTester(player: Player)
    return GroupUtil.getRank(player) >= RANK_TESTER
end

return GroupUtil
