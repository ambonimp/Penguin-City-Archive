local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
--[[
    We cannot query on the client the network owner of a part. Cheers Roblox! Wrapping API in this file gives us this functionality.
]]
local NetworkOwnerUtil = {}

local ATTRIBUTE_NETWORK_OWNER = "_NetworkOwnerUserId"

--[[
    Sets NetworkOwner for a specific BasePart, or all BaseParts found inside the model
]]
function NetworkOwnerUtil.setNetworkOwner(instance: BasePart | Model, player: Player?)
    if instance:IsA("Model") then
        for _, descendant in pairs(instance:GetDescendants()) do
            if descendant:IsA("BasePart") then
                NetworkOwnerUtil.setNetworkOwner(descendant, player)
            end
        end

        return
    end

    instance:SetNetworkOwner(player)
    instance:SetAttribute(ATTRIBUTE_NETWORK_OWNER, player and player.UserId)
end

function NetworkOwnerUtil.getNetworkOwner(instance: BasePart)
    if RunService:IsServer() then
        return instance:GetNetworkOwner()
    end

    local userId = instance:GetAttribute(ATTRIBUTE_NETWORK_OWNER)
    return userId and Players:GetPlayerByUserId(userId) or nil
end

return NetworkOwnerUtil
