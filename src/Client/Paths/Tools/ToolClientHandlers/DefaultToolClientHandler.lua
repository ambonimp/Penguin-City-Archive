local DefaultToolHandler = {}

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
local Maid = require(Paths.Packages.maid)

--[[
    `modelSignal` is fired twice; once with our locally created model and once with the server created model
]]
function DefaultToolHandler.equipped(_tool: ToolUtil.Tool, _modelSignal: Signal.Signal, _equipMaid: typeof(Maid.new()))
    --
end

function DefaultToolHandler.unequipped(_tool: ToolUtil.Tool)
    --
end

function DefaultToolHandler.activatedLocally(_tool: ToolUtil.Tool, _model: Model)
    --
end

function DefaultToolHandler.activatedRemotely(_player: Player, _tool: ToolUtil.Tool, _data: table?)
    --
end

return DefaultToolHandler
