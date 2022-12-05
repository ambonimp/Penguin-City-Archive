local DefaultToolServerHandler = {}

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

--[[
    `modelSignal` is fired twice; once with our locally created model and once with the server created model
]]
function DefaultToolServerHandler.equipped(_player: Player, _tool: ToolUtil.Tool, _model: Model, _equipMaid: typeof(Maid.new()))
    --
end

function DefaultToolServerHandler.unequipped(_player: Player, _tool: ToolUtil.Tool)
    --
end

function DefaultToolServerHandler.activated(_player: Player, _tool: ToolUtil.Tool, _model: Model, _dirtyData: table)
    --
end

return DefaultToolServerHandler
