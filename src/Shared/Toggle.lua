--[[
    Wrapper for a boolean variable that manages potentially conflicting value changes.

    Example:
        local toggle = Toggle.new(true, print)

        toggle:Set(false, "a") -- "a" (conflicts with previous bool value)
        toggle:Set(false, "b") -- ""
        toggle:Set(true, "c") -- ""
        toggle:Set(true, "b") -- "b"
]]

local Toggle = {}

function Toggle.new(initialValue: boolean, onToggled: (boolean) -> ())
    local toggle = {}

    local jobs: { any } = {}
    local value = initialValue

    --[[
        Change the value, if flipping back the value to the initial value, all jobs must agree
    ]]
    function toggle:Set(newValue: boolean, job: any)
        if newValue ~= initialValue then
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

    -- Calls internal onToggled callback without alterating internal workings of Toggle
    function toggle:CallOnToggled(forceValue: boolean)
        onToggled(forceValue)
    end

    return toggle
end

return Toggle
