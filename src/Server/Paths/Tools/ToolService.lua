local ToolService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local PlayerService = require(Paths.Server.PlayerService)
local Maid = require(Paths.Shared.Maid)
local Signal = require(Paths.Shared.Signal)

type EquippedData = {
    Tool: ToolUtil.Tool | nil,
    Model: Model | nil,
    EquipMaid: Maid.Maid,
}

type ToolServerHandler = {
    equipped: ((player: Player, tool: ToolUtil.Tool, model: Model, equipMaid: Maid.Maid) -> any),
    unequipped: ((player: Player, tool: ToolUtil.Tool) -> any),
    activated: ((player: Player, tool: ToolUtil.Tool, model: Model, dirtyData: table) -> any),
}

ToolService.ToolEquipped = Signal.new() -- { player: Player, tool: ToolUtil.Tool }
ToolService.ToolUnequipped = Signal.new() -- { player: Player, tool: ToolUtil.Tool }

local equippedDataByPlayer: { [Player]: EquippedData } = {}

function ToolService.loadPlayer(player: Player)
    equippedDataByPlayer[player] = {
        EquipMaid = Maid.new(),
    }

    PlayerService.getPlayerMaid(player):GiveTask(function()
        if equippedDataByPlayer[player] then
            equippedDataByPlayer[player].EquipMaid:Destroy()
            equippedDataByPlayer[player] = nil
        end
    end)
end

-------------------------------------------------------------------------------
-- Tool Handlers
-------------------------------------------------------------------------------

local function getDefaultToolServerHandler(): ToolServerHandler
    return require(Paths.Server.Tools.ToolServerHandlers.DefaultToolServerHandler)
end

local function getToolServerHandler(tool: ToolUtil.Tool): ToolServerHandler | {}
    local toolClientHandlerName = ("%sToolServerHandler"):format(tool.CategoryName)
    local toolClientHandler = Paths.Server.Tools.ToolServerHandlers:FindFirstChild(toolClientHandlerName)
    if toolClientHandler then
        return require(toolClientHandler)
    end

    return {}
end

-------------------------------------------------------------------------------
-- Equipping
-------------------------------------------------------------------------------

function ToolService.equip(player: Player, tool: ToolUtil.Tool)
    -- RETURN: Already equipped!
    local equippedData = equippedDataByPlayer[player]
    if equippedData.Tool and ToolUtil.toolsMatch(equippedData.Tool, tool) then
        return equippedData.Model
    end

    -- Unequip old tool
    ToolService.unequip(player)
    equippedData.EquipMaid:Cleanup()

    -- WARN: No character!
    local character = player.Character
    if not character then
        warn(("Cannot equip for %s; no character!"):format(player.Name))
        return nil
    end

    -- Model
    local model = ToolUtil.hold(character, tool)

    -- Cache
    equippedData.Model = model
    equippedData.Tool = tool

    -- Handler
    local toolServerHandler = getToolServerHandler(tool)
    local equipped = toolServerHandler and toolServerHandler.equipped or getDefaultToolServerHandler().equipped
    equipped(player, tool, model, equippedData.EquipMaid)

    ToolService.ToolEquipped:Fire(player, tool)

    return model
end

function ToolService.unequip(player: Player)
    local equippedData = equippedDataByPlayer[player]

    -- Model
    if equippedData.Model then
        equippedData.Model:Destroy()
    end

    -- Handler
    if equippedData.Tool then
        local toolServerHandler = getToolServerHandler(equippedData.Tool)
        local unequipped = toolServerHandler and toolServerHandler.unequipped or getDefaultToolServerHandler().unequipped
        unequipped(player, equippedData.Tool)

        ToolService.ToolUnequipped:Fire(player, equippedData.Tool)
    end

    equippedData.Model = nil
    equippedData.Tool = nil
end

-- Communication
Remotes.bindFunctions({
    ToolEquipRequest = function(player: Player, dirtyCategoryName: any, dirtyToolId: any)
        -- Clean Data
        local success, tool = pcall(ToolUtil.tool, tostring(dirtyCategoryName), tostring(dirtyToolId))
        if not success then
            return
        end

        return ToolService.equip(player, tool)
    end,
})
Remotes.bindEvents({
    ToolUnequip = function(player: Player)
        ToolService.unequip(player)
    end,
    ToolActivated = function(player: Player, dirtyCategoryName: any, dirtyToolId: any, dirtyData: any)
        -- Clean Data
        local success, tool = pcall(ToolUtil.tool, tostring(dirtyCategoryName), tostring(dirtyToolId))
        if not success then
            return
        end

        if typeof(dirtyData) ~= "table" then
            return
        end

        -- WARN: No equipped data?
        local equippedData = equippedDataByPlayer[player]
        if not equippedData then
            warn("No equipped data for", player.Name)
            return
        end

        -- RETURN: Not equipped / no model
        if not (equippedData.Tool and ToolUtil.toolsMatch(equippedData.Tool, tool) and equippedData.Model) then
            return
        end

        local toolServerHandler = getToolServerHandler(tool)
        local activated = toolServerHandler and toolServerHandler.activated or getDefaultToolServerHandler().activated
        activated(player, equippedData.Tool, equippedData.Model, dirtyData)
    end,
})
Remotes.declareEvent("ToolActivatedRemotely")

return ToolService
