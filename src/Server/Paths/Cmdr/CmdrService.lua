local CmdrService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CmdrUtil = require(Paths.Shared.Cmdr.CmdrUtil)

-- Takes a while to load, so put on a separate thread
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Cmdr = require(ReplicatedStorage.Packages.cmdr)

    Cmdr:RegisterDefaultCommands()
    Cmdr:RegisterCommandsIn(script.Parent.Commands)

    Cmdr.Registry:RegisterHook("BeforeRun", function(context)
        local player: Player = context.Executor
        if not CmdrUtil.IsAdmin(player) then
            return "You do not have permission to use this command"
        end
    end)
end)

return CmdrService
