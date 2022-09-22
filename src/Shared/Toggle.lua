--[[
    Wrapper for a boolean variable that manages potentially conflicting value changes
]]

local Class = {}
Class.__index = Class

function Class.new(value: boolean, onToggled: (boolean) -> ())
    local self = {}
    local jobs = {}

    --[[
        Set the toggles value. If setting to fall, all jobs must agree
    ]]
    function self:Set(newValue: boolean, job: any)
        if newValue then
            if not table.find(jobs, job) then
                if value ~= newValue then
                    value = true
                    onToggled(true)
                end

                table.insert(jobs, job)
            end
        else
            local jobIndex = table.find(jobs, job)
            if jobIndex then
                table.remove(jobs, jobIndex)

                if #jobs == 0 then
                    value = false
                    onToggled(false)
                end
            end
        end
    end

    return self
end

return Class
