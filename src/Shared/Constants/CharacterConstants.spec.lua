local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConstants = require(ReplicatedStorage.Shared.Constants.CharacterConstants)

return function()
    local issues: { string } = {}

    -- Emote names are good
    for _, emoteName in pairs(CharacterConstants.EmoteNames) do
        if not CharacterConstants.Animations[emoteName] then
            table.insert(issues, (("EmoteName %q entry not found in CharacterConstants.Animations"):format(emoteName)))
        end
    end

    return issues
end
