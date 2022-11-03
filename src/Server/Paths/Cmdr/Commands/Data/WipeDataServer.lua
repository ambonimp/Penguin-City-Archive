local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)

return function(_context, players: { Player }, confirmString: string)
    -- BAD CONFIRM STRING
    if confirmString ~= "WIPE" then
        return "Did not wipe data - please type `WIPE` as the end parameter to confirm."
    end

    local output = ""

    for _, player in pairs(players) do
        DataService.wipe(player)
        output ..= (" > %s wiped\n"):format(player.Name)
    end

    return output
end
