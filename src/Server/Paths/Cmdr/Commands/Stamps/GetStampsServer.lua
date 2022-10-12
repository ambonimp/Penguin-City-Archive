local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.StampService)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        output ..= (" > %s:\n"):format(player.Name)

        local ownsAnyStamp = false
        for _, stampType in pairs(Stamps.StampTypes) do
            local stampTypeOutput = ("    %s\n"):format(stampType)
            local ownsAStamp = false
            for _, stamp in pairs(StampUtil.getStampsFromType(stampType)) do
                if StampService.hasStamp(player, stamp.Id) then
                    stampTypeOutput ..= ("       %s (%s)\n"):format(stamp.Id, stamp.DisplayName)
                    ownsAStamp = true
                end
            end

            if ownsAStamp then
                output ..= stampTypeOutput
                ownsAnyStamp = true
            end
        end

        if not ownsAnyStamp then
            output ..= "     No stamps - what a noob!"
        end
    end

    return output
end
