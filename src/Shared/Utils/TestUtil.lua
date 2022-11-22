local TestUtil = {}

--[[
    Ensures the passed table is "Enum-Like", where keys equal values.

    Will insert an error message into `issues` - or simply throw an error if it is not passed
]]
function TestUtil.enum(tbl: table, issues: { string }?)
    for k, v in pairs(tbl) do
        if k ~= v then
            local errorMessage = ("Key: %q, Value: %q - must be equal!"):format(tostring(k), tostring(v))
            if issues then
                table.insert(issues, errorMessage)
            else
                error(errorMessage)
            end
        end
    end
end

return TestUtil
