local PathsUtil = {}

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
