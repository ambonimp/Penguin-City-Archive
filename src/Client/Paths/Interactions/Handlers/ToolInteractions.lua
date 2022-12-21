local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local ToolController = require(Paths.Client.Tools.ToolController)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)

InteractionController.registerInteraction("EquipTool", function(instance)
    local toolName = instance:GetAttribute("Tool")
    local categoryName = instance:GetAttribute("Category")
    if toolName and categoryName then
        local tool = ToolUtil.tool(categoryName, toolName)

        local equippedTool = ToolController.getEquipped()

        if equippedTool then
            ToolController.unequip(equippedTool) --if a tool is equipped, unequip it first
            if ToolUtil.toolsMatch(equippedTool, tool) then --if tools are the same then return
                return
            end
        end

        if ToolController.isHolstered(tool) then
            ToolController.equipRequest(tool)
        else
            ToolController.holster(tool)
            ToolController.equipRequest(tool)
        end
    end
end)

return MinigamePromptInteraction
