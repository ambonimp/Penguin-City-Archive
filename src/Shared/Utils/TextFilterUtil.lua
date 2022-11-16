local TextFilterUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TypeUtil = require(ReplicatedStorage.Shared.Utils.TypeUtil)

--[[
    Returns an Instance with multiple methods for getting the filtered text, depending on the context

    https://create.roblox.com/docs/reference/engine/classes/TextFilterResult
]]
function TextFilterUtil.filter(text: string, fromUserId: number, textContext: Enum.TextFilterContext?)
    -- CLIENT: Must request server
    if RunService:IsClient() then
        return Remotes.invokeServer("TextFilterUtilFilter", text)
    end

    local textFilterResult: TextFilterResult
    local success, err = pcall(function()
        textFilterResult = TextService:FilterStringAsync(text, fromUserId, textContext)
    end)
    if not success then
        warn(err)
        return nil
    end

    return textFilterResult:GetNonChatStringForBroadcastAsync() -- Safest, most generic method.
end

function TextFilterUtil.wasFiltered(originalText: string, filteredText: string)
    local _, originalHashes = string.gsub(originalText, "#", "")
    local _, filteredHashes = string.gsub(filteredText, "#", "")
    return filteredHashes > originalHashes
end

-- Client Requests
do
    if RunService:IsServer() then
        Remotes.bindFunctions({
            TextFilterUtilFilter = function(player: Player, dirtyText: any)
                local text = TypeUtil.toString(dirtyText)
                if text then
                    return TextFilterUtil.filter(text, player.UserId)
                end
            end,
        })
    end
end

return TextFilterUtil
