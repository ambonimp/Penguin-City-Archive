local PathsUtil = {}

function PathsUtil.createModules(directories: { Instance })
    local function populate(instanceTable: { [string]: Instance | table }, instance: Instance)
        for _, child in pairs(instance:GetChildren()) do
            local childName = child.Name
            local duplicateChild: Instance = instanceTable[childName]
            if duplicateChild and duplicateChild.IsA then
                -- Special treatment for duplicates
                if duplicateChild:IsA("Folder") then
                    instanceTable[childName] = {}
                    populate(instanceTable[childName], child)
                    populate(instanceTable[childName], duplicateChild)
                else
                    error(("Duplicate non-Folders (%s) (%s)"):format(duplicateChild:GetFullName(), child:GetFullName()))
                end
            else
                -- Populate table
                instanceTable[childName] = child
            end
        end
    end

    local modules = {}
    for _, directory in pairs(directories) do
        populate(modules, directory)
    end

    print(modules)

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
