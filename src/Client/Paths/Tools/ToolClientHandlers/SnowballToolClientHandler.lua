local SnowballToolClientHandler = {}

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
local SnowballToolUtil = require(Paths.Shared.Tools.Utils.SnowballToolUtil)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- Snowball Logic
-------------------------------------------------------------------------------

local function throwSnowball(position: Vector3, snowballModel: Model)
    --!! temp
    DebugUtil.flashPoint(position, snowballModel.PrimaryPart.Color)
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

function SnowballToolClientHandler.equipped(_tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new()))
    -- Hide snowball by default
    equipMaid:GiveTask(modelSignal:Connect(function(snowballModel: Model, oldLocalSnowballModel: Model?)
        SnowballToolUtil.hideSnowball(snowballModel)

        -- We have just got the new server model - but what if we were already throwing our local version and it was visible?
        if oldLocalSnowballModel then
            SnowballToolUtil.matchSnowball(snowballModel, oldLocalSnowballModel)
        end
    end))
end

function SnowballToolClientHandler.unequipped(tool: ToolUtil.Tool)
    print("unequipped", tool)
end

function SnowballToolClientHandler.activatedLocally(tool: ToolUtil.Tool, model: Model)
    -- RETURN: Bad raycast
    local mouseRaycastResult = MouseUtil.getMouseTarget()
    if not mouseRaycastResult then
        return
    end

    print("THROW LOCAL")
    throwSnowball(mouseRaycastResult.Position, model)

    -- Inform Server
    Remotes.fireServer("ToolActivated", tool.CategoryName, tool.ToolName, {
        Position = mouseRaycastResult.Position,
    })
end

function SnowballToolClientHandler.activatedRemotely(player: Player, tool: ToolUtil.Tool, model: Model?, data: table?)
    -- RETURN: No model
    if not model then
        return
    end

    -- RETURN: Bad data
    local position = data and data.Position
    if not position then
        warn("Bad data passed", data)
        return
    end

    print("THROW REMOTE")
    throwSnowball(position, model)
end

return SnowballToolClientHandler
