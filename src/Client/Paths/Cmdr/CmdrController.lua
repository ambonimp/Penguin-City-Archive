local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CmdrUtil = require(Paths.Shared.Utils.CmdrUtil)
local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))

CmdrClient:SetActivationKeys({ Enum.KeyCode.Semicolon })

CmdrClient.Registry:RegisterHook("BeforeRun", function(context)
    local player: Player = context.Executor
    if not CmdrUtil.IsAdmin(player) then
        return "You do not have permission to use this command"
    end
end)

return CmdrController
