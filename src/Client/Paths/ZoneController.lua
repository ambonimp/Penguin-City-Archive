local ZoneController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)

-- Communication
do
    Remotes.bindEvents({
        ZoneChanged = function(zoneType: string, zoneId: string, teleportBuffer: number)
            print(zoneType, zoneId, teleportBuffer)
        end,
    })
end

return ZoneController
