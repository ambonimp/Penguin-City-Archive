--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]
--

local HouseDefaullt = {}

function HouseDefaullt.getDefaults()
    return {
        ["Chair"] = { Id = 0, Position = { 0, 2.6, 0 }, Rotation = { 0, 0, 0 }, Color = { 124, 92, 70 } },
    }
end

return HouseDefaullt
