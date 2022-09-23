local PathsUtil = {}

function PathsUtil.createModules(directories: { Instance })
    local modules = {}

    for _, directory in pairs(directories) do
        for _, child in pairs(directory:GetChildren()) do
            -- ERROR: Duplicate name
            local childName = child.Name
            local duplicateChild = modules[childName]
            if duplicateChild then
                error(("Duplicate named modules (%s) (%s)"):format(duplicateChild:GetFullName(), child:GetFullName()))
            end

            modules[childName] = child
        end
    end

    return modules
end

function PathsUtil.runInitAndStart(requiredModules: { table })
    -- Run Init (Syncchronous)
    for _, tbl in pairs(requiredModules) do
        if tbl.Init then
            tbl.Init()
        end
    end

    -- Run Start
    for _, tbl in pairs(requiredModules) do
        if tbl.Start then
            task.spawn(tbl.Start)
        end
    end
end

return PathsUtil
