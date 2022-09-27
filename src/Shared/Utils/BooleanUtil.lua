local BooleanUtil = {}

function BooleanUtil.returnFirstBoolean(...: boolean | any | nil)
    local variables = table.pack(...)

    for _, variable in pairs(variables) do
        if variable == true or variable == false then
            return variable
        end
    end
end

return BooleanUtil
