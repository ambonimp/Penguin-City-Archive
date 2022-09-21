--[[
    Useful API for interacting with the Penguin City Roblox Group
    ]]
local GroupUtil = {}

local RunService = game:GetService("RunService")

local GROUP_ID = 12843903
local RANK_ADMIN = 250
local IS_STUDIO = RunService:IsStudio()

-- Yields on first call, but Roblox API uses a cache afterwards.
function GroupUtil.getRank(player: Player)
    return player:GetRankInGroup(GROUP_ID)
end

function GroupUtil.isAdmin(player: Player)
    return IS_STUDIO or GroupUtil.getRank(player) >= RANK_ADMIN
end

return GroupUtil
