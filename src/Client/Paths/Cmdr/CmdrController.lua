local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CmdrUtil = require(Paths.Shared.Cmdr.CmdrUtil)
local Remotes = require(Paths.Shared.Remotes)
local Permissions = require(Paths.Shared.Permissions)
local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local CLIENT_SUFFIX = "Client"

local commandNameToInvokeCallback: { [string]: (...any) -> nil } = {}

-- Has recieved instruction from the server to run some logic
function CmdrController.runClientLogic(commandName: string, ...: any)
    -- ERROR: No invoke callback
    local invokeCallback = commandNameToInvokeCallback[commandName]
    if not invokeCallback then
        error(("No invoke callback for commandName %q"):format(commandName))
    end

    invokeCallback(...)
end

-- Load command invoke callbacks
do
    for _, moduleScript in pairs(script.Parent.InvokedCommands:GetDescendants()) do
        if moduleScript:IsA("ModuleScript") then
            -- ERROR: No Client suffix
            local name = moduleScript.Name
            local suffix = string.sub(name, (string.len(name) - string.len(CLIENT_SUFFIX) + 1))
            if not suffix == CLIENT_SUFFIX then
                error(("Client command %q needs '%s' suffix"):format(name, CLIENT_SUFFIX))
            end

            local noSuffixName = string.sub(name, 0, (string.len(name) - string.len(CLIENT_SUFFIX)))
            commandNameToInvokeCallback[noSuffixName] = require(moduleScript)
        end
    end
end

-- Cmdr Setup
do
    if Permissions.isAdmin(Players.LocalPlayer) then
        CmdrClient:SetActivationKeys({ Enum.KeyCode.Semicolon })
    else
        CmdrClient:SetActivationKeys({})
    end

    CmdrClient.Registry:RegisterHook("BeforeRun", function(context)
        local player: Player = context.Executor
        if not CmdrUtil.IsAdmin(player) then
            return "You do not have permission to use this command"
        end
    end)
end

-- Communication
do
    Remotes.bindEvents({
        CmdrRunClientLogic = CmdrController.runClientLogic,
    })
end

return CmdrController
