local CmdrService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CmdrUtil = require(Paths.Shared.Cmdr.CmdrUtil)
local Remotes = require(Paths.Shared.Remotes)

local DISABLED_DEFAULT_COMMANDS = { "teleport" }

-- Inform a client to run some logic in the context of a command
function CmdrService.invokeClientLogic(client: Player, commandName: string, ...: any)
    Remotes.fireClient(client, "CmdrRunClientLogic", commandName, ...)
end
Remotes.declareEvent("CmdrRunClientLogic")

-- Takes a while to load, so put on a separate thread
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Cmdr = require(ReplicatedStorage.Packages.cmdr)

    Cmdr:RegisterDefaultCommands(function(cmd)
        if table.find(DISABLED_DEFAULT_COMMANDS, cmd.Name) then
            return false
        end
        return true
    end)
    Cmdr:RegisterCommandsIn(script.Parent.Commands)
    Cmdr:RegisterTypesIn(script.Parent.Types)

    Cmdr.Registry:RegisterHook("BeforeRun", function(context)
        local player: Player = context.Executor
        if not CmdrUtil.IsAdmin(player) then
            return "You do not have permission to use this command"
        end
    end)
end)

return CmdrService
