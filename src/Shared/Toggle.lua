--[[
    Wrapper for a boolean variable that manages potentially conflicting value changes.

    Example:
        local toggle = Toggle.new(true)

        toggle:Set(false, "a")
        print(toggle:Get()) -- false
        toggle:Set(false, "b")
        print(toggle:Get()) -- false
        toggle:Set(true, "a")
        print(toggle:Get()) -- false
        toggle:Set(true, "b")
        print(toggle:Get()) -- true

]]

local Toggle = {}

function Toggle.new(initialValue: boolean, onToggled: (value: boolean) -> ()?)
    local toggle = {}

    local jobs: { any } = {}
    local value = initialValue

    -- Change the value, if flipping back the value to the initial value, all jobs must agree
    function toggle:Set(newValue: boolean, job: any)
        if newValue ~= initialValue then
            -- RETURN: Job already exists
            if table.find(jobs, job) then
                return
            end

            if value ~= newValue then
                value = true

                if onToggled then
                    onToggled(newValue)
                end
            end

            table.insert(jobs, job)
        else
            local jobIndex = table.find(jobs, job)
            -- RETURN: Job doesn't exist
            if not jobIndex then
                return
            end

            table.remove(jobs, jobIndex)

            if #jobs == 0 then
                value = false

                if onToggled then
                    onToggled(newValue)
                end
            end
        end
    end

    function toggle:RemoveJob(job: any)
        if table.find(jobs, job) then
            toggle:Set(not value, job)
        end
    end

    function toggle:ForceSet(newValue)
        if onToggled then
            onToggled(newValue)
        end

        jobs = {}
        value = newValue
    end

    function toggle:Get(): boolean
        return value
    end

    -- Calls internal onToggled callback without alterating internal workings of Toggle
    function toggle:CallOnToggled(forceValue: boolean)
        onToggled(forceValue)
    end

    return toggle
end

return Toggle
