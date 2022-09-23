--[[
    Wrapper for a boolean variable that manages potentially conflicting value changes
]]

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(value: boolean, onToggled: (boolean) -> ())
    local toggle = {}
    local jobs = {}

    --[[
        Set the toggles value. If setting to false, all jobs must agree
    ]]
    function toggle:Set(newValue: boolean, job: any)
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

    return toggle
end

return Toggle
