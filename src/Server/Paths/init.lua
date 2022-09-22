local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages

Paths.Initialized = false

-- Curate Modules
-- `Modules` has intellisense + actual access to files under: Shared, Packages, Paths
local directories: { Instance } = { Shared, Packages, script }
local modules: typeof(Shared) & typeof(Packages) & typeof(script) = {}

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

Paths.Modules = modules

-- Loading Coroutine
task.spawn(function()
    -- Require necessary files
    local requiredModules = {}

    -- Sort by load order
    table.sort(requiredModules, function(tbl1, tbl2)
        local loadOrder1 = tbl1._loadOrder or 0
        local loadOrder2 = tbl2._loadOrder or 0

        if loadOrder1 ~= loadOrder2 then
            return loadOrder1 < loadOrder2
        end

        return tostring(tbl1) < tostring(tbl2)
    end)

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
end)

return Paths
