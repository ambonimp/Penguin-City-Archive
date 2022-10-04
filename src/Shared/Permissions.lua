--[[
    Central place for deciding if a player has permission for something
]]
local Permissions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GroupUtil = require(ReplicatedStorage.Shared.Utils.GroupUtil)
local GameUtil = require(ReplicatedStorage.Shared.Utils.GameUtil)

function Permissions.isAdmin(player: Player)
    -- TRUE: Studio
    if RunService:IsStudio() then
        return true
    end

    if GameUtil.isLiveGame() then
        return GroupUtil.isAdmin(player)
    end
    if GameUtil.isQAGame() then
        return GroupUtil.isTester(player)
    end

    return true
end

function Permissions.isTester(player: Player)
    -- TRUE: Studio
    if RunService:IsStudio() then
        return true
    end

    if GameUtil.isLiveGame() then
        return GroupUtil.isTester(player)
    end

    return true
end

return Permissions
