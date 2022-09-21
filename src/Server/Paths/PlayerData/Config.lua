--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]
--

local DataConfig = {}

local Paths = require(script.Parent.Parent)
local modules = Paths.Modules

DataConfig.DataKey = "DEV_1"
function DataConfig.getDefaults(player)
    return {
        MyPenguin = {
            ["Name"] = player.DisplayName,
        },
        Igloo = {},
        Gamepasses = {},
        Settings = {},
        RedeemedCodes = {},
    }
end

return DataConfig
