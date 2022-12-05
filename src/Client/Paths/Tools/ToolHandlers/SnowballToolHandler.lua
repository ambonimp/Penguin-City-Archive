local SnowballToolHandler = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local Assume = require(Paths.Shared.Assume)
local Remotes = require(Paths.Shared.Remotes)
local Scope = require(Paths.Shared.Scope)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Maid = require(Paths.Packages.maid)

function SnowballToolHandler.equipped(tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new()))
    equipMaid:GiveTask(modelSignal:Connect(function(snowballModel: Model)
        print("snowball", snowballModel)
        InstanceUtil.hide(snowballModel)
    end))
end

-- function SnowballToolHandler.unequipped(tool: ToolUtil.Tool)
--     print("unequipped", tool)
-- end

-- function SnowballToolHandler.activatedLocally(tool: ToolUtil.Tool, modelGetter: () -> Model?)
--     print("activated locally", tool, modelGetter())
-- end

-- function SnowballToolHandler.activatedRemotely(player: Player, tool: ToolUtil.Tool, data: table?)
--     print("activated remotely", player, tool, data)
-- end

return SnowballToolHandler
