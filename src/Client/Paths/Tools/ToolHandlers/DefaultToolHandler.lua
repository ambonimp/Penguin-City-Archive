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
function DefaultToolHandler.equipped(tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new()))
    print("equipped", tool)
end

function DefaultToolHandler.unequipped(tool: ToolUtil.Tool)
    print("unequipped", tool)
end

function DefaultToolHandler.activatedLocally(tool: ToolUtil.Tool, modelGetter: () -> Model?)
    print("activated locally", tool, modelGetter())
end

function DefaultToolHandler.activatedRemotely(player: Player, tool: ToolUtil.Tool, data: table?)
    print("activated remotely", player, tool, data)
end

return DefaultToolHandler
