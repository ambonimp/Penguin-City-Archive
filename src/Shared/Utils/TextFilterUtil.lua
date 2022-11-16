local TextFilterUtil = {}

local TextService = game:GetService("TextService")

--[[
    Returns an Instance with multiple methods for getting the filtered text, depending on the context

    https://create.roblox.com/docs/reference/engine/classes/TextFilterResult
]]
function TextFilterUtil.filter(text: string, fromUserId: number, textContext: Enum.TextFilterContext?)
    local textFilterResult: TextFilterResult
    local success, err = pcall(function()
        textFilterResult = TextService:FilterStringAsync(text, fromUserId, textContext)
    end)
    if not success then
        warn(err)
        return nil
    end

    return textFilterResult
end

function TextFilterUtil.wasFiltered(originalText: string, filteredText: string)
    local _, originalHashes = string.gsub(originalText, "#", "")
    local _, filteredHashes = string.gsub(filteredText, "#", "")
    return filteredHashes > originalHashes
end

return TextFilterUtil
