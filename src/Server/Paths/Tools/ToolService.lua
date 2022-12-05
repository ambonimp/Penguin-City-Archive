local ToolService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local PlayerService = require(Paths.Server.PlayerService)
local Maid = require(Paths.Packages.maid)

type EquippedData = {
    Tool: ToolUtil.Tool | nil,
    Model: Model | nil,
    EquipMaid: typeof(Maid.new()),
}

type ToolServerHandler = {
    equipped: ((player: Player, tool: ToolUtil.Tool, model: Model, equipMaid: typeof(Maid.new())) -> any),
    unequipped: ((player: Player, tool: ToolUtil.Tool) -> any),
    activated: ((player: Player, tool: ToolUtil.Tool, model: Model) -> any),
}

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
    return require(Paths.Client.Tools.ToolServerHandlers.DefaultToolServerHandler)
end

local function getToolServerHandler(tool: ToolUtil.Tool): ToolServerHandler | {}
    local toolClientHandlerName = ("%sToolServerHandler"):format(tool.CategoryName)
    local toolClientHandler = Paths.Client.Tools.ToolServerHandlers:FindFirstChild(toolClientHandlerName)
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
    model.PrimaryPart:SetNetworkOwner(player)

    -- Cache
    equippedData.Model = model
    equippedData.Tool = tool

    -- Handler
    local toolServerHandler = getToolServerHandler(tool)
    local equipped = toolServerHandler and toolServerHandler.equipped or getDefaultToolServerHandler().equipped
    equipped(player, tool, model, equippedData.EquipMaid)

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
    end

    equippedData.Model = nil
    equippedData.Tool = nil
end

-- Communication
Remotes.bindFunctions({
    ToolEquipRequest = function(player: Player, dirtyCategoryName: any, dirtyToolName: any)
        -- Clean Data
        local success, tool = pcall(ToolUtil.tool, tostring(dirtyCategoryName), tostring(dirtyToolName))
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
})

return ToolService
