--[[
    RULES
    - No spaces in keys, use underscores or preferably just camel case instead
]]
--

local HouseDefault = {}

function HouseDefault.getDefaults()
    return {
        ["1"] = { Id = 1, Position = { 0, 2.6, -16 }, Rotation = { 0, 0, 0 }, Color = { 124, 92, 70 }, Name = "Chair" },
    }
end

function HouseDefault.getFurnitureDefaults()
    return {
        ["Chair"] = 3,
        ["Couch"] = 3,
        ["Plant"] = 3,
        ["Table"] = 3,
        ["Table_Lamp"] = 3,
    }
end

function HouseDefault.getIglooDefaults()
    return {
        IglooPlot = "Default",
        IglooHouse = "Default",
        Placements = HouseDefault.getDefaults(),
        OwnedItems = HouseDefault.getFurnitureDefaults(),
    }
end

return HouseDefault
