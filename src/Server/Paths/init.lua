local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages

Paths.Initialized = false

-- Curate Modules
-- `Modules` has intellisense + actual access to files under: Shared, Packages, Paths
local directories: { Instance } = { Shared, Packages, script }
local modules: (typeof(Shared) & typeof(Packages) & typeof(script)) | table = {}

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
task.delay(0, function()
    -- Require necessary files
    local requiredModulesInOrder = {
        -- Systems
        require(modules.PlayerData),
        require(modules.PlayerLoader),
        require(modules.AnalyticsTracking),
        require(modules.Vehicles),
        require(modules.Cmdr.CmdrService),
    }

    -- Run Init (Syncchronous)
    for _, tbl in pairs(requiredModulesInOrder) do
        if tbl.Init then
            tbl.Init()
        end
    end

    -- Run Start
    for _, tbl in pairs(requiredModulesInOrder) do
        if tbl.Start then
            task.spawn(tbl.Start)
        end
    end
end)

return Paths
