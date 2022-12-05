local SnowballToolServerHandler = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Signal = require(Paths.Shared.Signal)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local Assume = require(Paths.Shared.Assume)
local Remotes = require(Paths.Shared.Remotes)
local Scope = require(Paths.Shared.Scope)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Maid = require(Paths.Packages.maid)
local SnowballToolUtil = require(Paths.Shared.Tools.Utils.SnowballToolUtil)

function SnowballToolServerHandler.equipped(player: Player, tool: ToolUtil.Tool, snowballModel: Model, equipMaid: typeof(Maid.new()))
    -- Hide snowball by default
    SnowballToolUtil.hideSnowball(snowballModel)
end

function SnowballToolServerHandler.unequipped(player: Player, tool: ToolUtil.Tool)
    --
end

function SnowballToolServerHandler.activated(player: Player, tool: ToolUtil.Tool, model: Model)
    --
end

return SnowballToolServerHandler
