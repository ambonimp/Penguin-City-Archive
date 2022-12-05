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
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local ZoneService = require(Paths.Server.Zones.ZoneService)

function SnowballToolServerHandler.equipped(player: Player, tool: ToolUtil.Tool, snowballModel: Model, equipMaid: typeof(Maid.new()))
    -- Hide snowball by default
    SnowballToolUtil.hideSnowball(snowballModel)
end

function SnowballToolServerHandler.unequipped(player: Player, tool: ToolUtil.Tool)
    --
end

function SnowballToolServerHandler.activated(player: Player, tool: ToolUtil.Tool, model: Model, dirtyData: table)
    -- Clean Data
    local position: Vector3 = TypeUtil.toType(dirtyData.Position, "Vector3")
    if not position then
        return
    end

    -- Inform other Clients
    local otherPlayers = ZoneService.getPlayersInZone(ZoneService.getPlayerZone(player))
    for _, somePlayer in pairs(otherPlayers) do
        if somePlayer ~= player then
            Remotes.fireClient(somePlayer, "ToolActivatedRemotely", player, tool.CategoryName, tool.ToolId, {
                Position = position,
            })
        end
    end
end

return SnowballToolServerHandler
