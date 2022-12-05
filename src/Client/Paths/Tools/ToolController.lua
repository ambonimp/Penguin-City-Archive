local ToolController = {}

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
local InputController = require(Paths.Client.Input.InputController)
local Maid = require(Paths.Packages.maid)

type ToolClientHandler = {
    equipped: ((tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new())) -> any),
    unequipped: ((tool: ToolUtil.Tool) -> any),
    activatedLocally: ((tool: ToolUtil.Tool, model: Model) -> any),
    activatedRemotely: ((player: Player, tool: ToolUtil.Tool, data: table?) -> any),
}

ToolController.ToolEquipped = Signal.new() -- { tool: ToolUtil.Tool }
ToolController.ToolUnequipped = Signal.new() -- { tool: ToolUtil.Tool }
ToolController.ToolHolstered = Signal.new() -- { tool: ToolUtil.Tool }
ToolController.ToolUnholstered = Signal.new() -- { tool: ToolUtil.Tool }

local equipScope = Scope.new()
local equipMaid = Maid.new()

local holsteredTools: { ToolUtil.Tool } = {}
local equippedTool: ToolUtil.Tool | nil
local equippedToolModel: Model | nil

function ToolController.Start()
    -- Track activation of tools
    do
        local wasCursorDownAGameProcessedEvent: boolean
        InputController.CursorDown:Connect(function(gameProcessedEvent)
            wasCursorDownAGameProcessedEvent = gameProcessedEvent
        end)

        -- Local
        InputController.CursorUp:Connect(function(gameProcessedEvent)
            -- RETURN: Game processed event
            if wasCursorDownAGameProcessedEvent or gameProcessedEvent then
                return
            end

            -- RETURN: No equipped tool!
            if not equippedTool then
                return
            end

            print("Activate", equippedTool.ToolName, equippedTool.CategoryName)
        end)

        -- Remote
        --todo
    end
end

-------------------------------------------------------------------------------
-- Tool Handlers
-------------------------------------------------------------------------------

local function getDefaultToolClientHandler(): ToolClientHandler
    return require(Paths.Client.Tools.ToolClientHandlers.DefaultToolClientHandler)
end

local function getToolClientHandler(tool: ToolUtil.Tool): ToolClientHandler | {}
    local toolClientHandlerName = ("%sToolClientHandler"):format(tool.CategoryName)
    local toolClientHandler = Paths.Client.Tools.ToolClientHandlers:FindFirstChild(toolClientHandlerName)
    if toolClientHandler then
        return require(toolClientHandler)
    end

    return {}
end

-------------------------------------------------------------------------------
-- Querying
-------------------------------------------------------------------------------

function ToolController.isHolstered(tool: ToolUtil.Tool)
    for _, someTool in pairs(holsteredTools) do
        if ToolUtil.toolsMatch(someTool, tool) then
            return true
        end
    end

    return false
end

function ToolController.isEquipped(tool: ToolUtil.Tool)
    return equippedTool and ToolUtil.toolsMatch(equippedTool, tool)
end

function ToolController.getEquipped()
    return equippedTool
end

function ToolController.getHolsteredTools()
    return holsteredTools
end

function ToolController.getHolsteredProducts()
    local products: { Products.Product } = {}
    for _, holsteredTool in pairs(holsteredTools) do
        local product = ProductUtil.getToolProduct(holsteredTool.CategoryName, holsteredTool.ToolName)
        table.insert(products, product)
    end

    return products
end

-------------------------------------------------------------------------------
-- Equipping / Holstering
-------------------------------------------------------------------------------

-- Adds a tool to the toolbar
function ToolController.holster(tool: ToolUtil.Tool)
    -- RETURN: Already holstered!
    if ToolController.isHolstered(tool) then
        return
    end

    -- RETURN: Too many holstered tools!
    if #holsteredTools >= ToolConstants.MaxHolsteredTools then
        return
    end

    -- Add to cache + inform
    table.insert(holsteredTools, tool)
    ToolController.ToolHolstered:Fire(tool)
end

function ToolController.unholster(tool: ToolUtil.Tool)
    -- RETURN: Not holstered!
    if not ToolController.isHolstered(tool) then
        return
    end

    -- Remove from cache + Inform
    for index, someTool in pairs(holsteredTools) do
        if ToolUtil.toolsMatch(someTool, tool) then
            table.remove(holsteredTools, index)
            break
        end
    end
    ToolController.ToolUnholstered:Fire(tool)

    -- Unequip?
    if ToolController.isEquipped(tool) then
        ToolController.unequipRequest(tool)
    end
end

-- Has the player hold the tool
function ToolController.equipRequest(tool: ToolUtil.Tool)
    -- RETURN: Already equipped!
    if ToolController.isEquipped(tool) then
        return
    end

    -- RETURN: Not already holstered and too many holstered tools!
    if not ToolController.isHolstered(tool) and #holsteredTools >= ToolConstants.MaxHolsteredTools then
        warn("Max holstered tools")
        return
    end

    -- RETURN: No character!
    local character = Players.LocalPlayer.Character
    if not character then
        warn("No character")
        return
    end

    local thisEquipScopeId = equipScope:NewScope()
    equipMaid:Cleanup()

    -- Unequip old tool + update cache
    ToolController.unequip()
    equippedTool = tool

    -- Holster
    ToolController.holster(tool)

    -- Inform Client
    ToolController.ToolEquipped:Fire(tool)

    -- Inform Handler
    local modelSignal = Signal.new()
    equipMaid:GiveTask(modelSignal)

    local toolClientHandler = getToolClientHandler(tool)
    local equipped = toolClientHandler and toolClientHandler.equipped or getDefaultToolClientHandler().equipped
    equipped(tool, modelSignal, equipMaid)

    -- Request Server
    local assume = Assume.new(function()
        return Remotes.invokeServer("ToolEquipRequest", tool.CategoryName, tool.ToolName)
    end)
    assume:Check(function(result: Model | nil)
        return result and typeof(result) == "Instance" and result:IsA("Model")
    end)
    assume:Run(function()
        equippedToolModel = ToolUtil.hold(character, tool)
        modelSignal:Fire(equippedToolModel)
    end)
    assume:Then(function(serverToolModel: Model)
        -- Destroy Local version
        local oldLocalEquippedToolModel = equippedToolModel
        if equippedToolModel then
            equippedToolModel:Destroy()
            equippedToolModel = nil
        end

        -- Write server version if still in scope
        if thisEquipScopeId == equipScope:GetId() then
            equippedToolModel = serverToolModel
            modelSignal:Fire(serverToolModel, oldLocalEquippedToolModel)
        end
    end)
    assume:Else(function()
        -- Destroy Local version
        if equippedToolModel then
            equippedToolModel:Destroy()
            equippedToolModel = nil
        end
    end)
end

function ToolController.unequip(tool: ToolUtil.Tool | nil)
    tool = tool or equippedTool

    -- RETURN: Not equipped
    if not tool or not ToolController.isEquipped(tool) then
        return
    end

    -- Clear cache + model
    equippedTool = nil
    if equippedToolModel then
        equippedToolModel:Destroy()
        equippedToolModel = nil
    end

    -- Unholster
    ToolController.unholster(tool)

    -- Inform Client
    ToolController.ToolUnequipped:Fire(tool)

    -- Inform Handler
    do
        local toolClientHandler = getToolClientHandler(tool)
        local unequipped = toolClientHandler and toolClientHandler.unequipped or getDefaultToolClientHandler().unequipped
        unequipped(tool)
    end

    -- Inform Server
    Remotes.fireServer("ToolUnequip")
end

return ToolController
