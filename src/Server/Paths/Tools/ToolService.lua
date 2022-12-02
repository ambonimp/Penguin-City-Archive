local ToolService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local PlayerService = require(Paths.Server.PlayerService)

type EquippedData = {
    Tool: ToolUtil.Tool | nil,
    Model: Model | nil,
}

local equippedDataByPlayer: { [Player]: EquippedData } = {}

function ToolService.loadPlayer(player: Player)
    equippedDataByPlayer[player] = {}

    PlayerService.getPlayerMaid(player):GiveTask(function()
        equippedDataByPlayer[player] = nil
    end)
end

function ToolService.equip(player: Player, tool: ToolUtil.Tool)
    -- RETURN: Already equipped!
    local equippedData = equippedDataByPlayer[player]
    if equippedData.Tool and ToolUtil.toolsMatch(equippedData.Tool, tool) then
        return equippedData.Model
    end

    ToolService.unequip(player)

    -- WARN: No character!
    local character = player.Character
    if not character then
        warn(("Cannot equip for %s; no character!"):format(player.Name))
        return nil
    end

    local model = ToolUtil.hold(character, tool)
    --todo network ownership

    equippedData.Model = model
    equippedData.Tool = tool

    return model
end

function ToolService.unequip(player: Player)
    local equippedData = equippedDataByPlayer[player]

    if equippedData.Model then
        equippedData.Model:Destroy()
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
