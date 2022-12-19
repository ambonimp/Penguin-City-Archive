local ToolController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
local Maid = require(Paths.Shared.Maid)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIController = require(Paths.Client.UI.UIController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

type ToolClientHandler = {
    equipped: ((tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new())) -> any),
    unequipped: ((tool: ToolUtil.Tool) -> any),
    activatedLocally: ((tool: ToolUtil.Tool, modelGetter: () -> Model?) -> any),
    activatedRemotely: ((player: Player, tool: ToolUtil.Tool, model: Model?, data: table?) -> any),
}

local DESTROY_LOCAL_TOOL_MODEL_AFTER = 3
local INITIAL_TOOLBAR: { ToolUtil.Tool } = {
    ToolUtil.tool("Snowball", "Default"),
}
local HOLSTER_SLOTS_TO_KEYCODE = {
    [1] = Enum.KeyCode.One,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four,
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
local unequipCallback: (() -> any) | nil

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
-- Start
-------------------------------------------------------------------------------

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

            -- RETURN: Not in a permissive UI State
            if not UIUtil.isStateActivateToolPermissive(UIController.getStateMachine():GetState()) then
                return
            end

            local toolClientHandler = getToolClientHandler(equippedTool)
            local activatedLocally = toolClientHandler and toolClientHandler.activatedLocally
                or getDefaultToolClientHandler().activatedLocally
            activatedLocally(equippedTool, function()
                return equippedToolModel
            end)
        end)

        -- Remote
        Remotes.bindEvents({
            ToolActivatedRemotely = function(player: Player, categoryName: string, toolName: string, data: table?)
                -- Get Tool
                local tool = ToolUtil.tool(categoryName, toolName)

                -- Get Model
                local character = player.Character
                local toolModel = character and ToolUtil.getModelFromCharacter(tool, character)

                local toolClientHandler = getToolClientHandler(tool)
                local activatedRemotely = toolClientHandler and toolClientHandler.activatedRemotely
                    or getDefaultToolClientHandler().activatedRemotely
                activatedRemotely(player, tool, toolModel, data)
            end,
        })
    end

    -- Start with some default tools
    do
        UIUtil.waitForHudAndRoomZone(0.5):andThen(function()
            for _, tool in pairs(INITIAL_TOOLBAR) do
                ToolController.holster(tool)
            end
        end)
    end

    -- Keybinds
    do
        -- ERROR: Mismatch
        if TableUtil.length(HOLSTER_SLOTS_TO_KEYCODE) < ToolConstants.MaxHolsteredTools then
            error(
                ("HOLSTER_SLOTS_TO_KEYCODE has %d entries, max holstered tools is %d"):format(
                    TableUtil.length(HOLSTER_SLOTS_TO_KEYCODE),
                    ToolConstants.MaxHolsteredTools
                )
            )
        end

        UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
            -- RETURN: Game processed
            if gameProcessedEvent then
                return
            end

            -- Toggle equip state of tool that lines up with this input (if any)
            local hotbarIndex = TableUtil.find(HOLSTER_SLOTS_TO_KEYCODE, inputObject.KeyCode)
            if hotbarIndex then
                local tool = holsteredTools[hotbarIndex]
                if tool then
                    if ToolController.isEquipped(tool) then
                        ToolController.unequip(tool)
                    else
                        ToolController.equipRequest(tool)
                    end
                end
            end
        end)
    end

    -- Unequip in non-equip zones
    do
        local function unequipIfZoneIsBad(zone: ZoneConstants.Zone)
            if not ToolUtil.canEquipToolInZone(zone) and ToolController.getEquipped() then
                ToolController.unequip()
            end
        end

        ZoneController.ZoneChanged:Connect(function(_fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
            unequipIfZoneIsBad(toZone)
        end)
        unequipIfZoneIsBad(ZoneController.getCurrentZone())
    end
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

function ToolController.hasToolEquipped()
    return ToolController.getEquipped() and true or false
end

-- If holstered, returns the index the tool is holstered at
function ToolController.getHolsterSlot(tool: ToolUtil.Tool)
    for index, someTool in pairs(holsteredTools) do
        if ToolUtil.toolsMatch(someTool, tool) then
            return index
        end
    end

    return nil
end

function ToolController.getHolsteredTools()
    return holsteredTools
end

function ToolController.getHolsteredProducts()
    local products: { Products.Product } = {}
    for _, holsteredTool in pairs(holsteredTools) do
        local product = ProductUtil.getToolProduct(holsteredTool.CategoryName, holsteredTool.ToolId)
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
        ToolController.unequip(tool)
    end
end

-- Has the player hold the tool
function ToolController.equipRequest(tool: ToolUtil.Tool)
    -- RETURN: Not in an equip zone!
    if not ToolUtil.canEquipToolInZone(ZoneController.getCurrentZone()) then
        return
    end

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
    unequipCallback = equipped(tool, modelSignal, equipMaid)

    -- Request Server
    local assume = Assume.new(function()
        return Remotes.invokeServer("ToolEquipRequest", tool.CategoryName, tool.ToolId)
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
        if oldLocalEquippedToolModel then
            oldLocalEquippedToolModel.Parent = nil :: Instance
            task.delay(DESTROY_LOCAL_TOOL_MODEL_AFTER, function()
                oldLocalEquippedToolModel:Destroy()
            end)
        end

        -- Write server version if still in scope
        if thisEquipScopeId == equipScope:GetId() then
            equippedToolModel = serverToolModel
            modelSignal:Fire(serverToolModel, oldLocalEquippedToolModel)
        else
            equippedToolModel = nil
        end
    end)
    assume:Else(function()
        ToolController.unequip(tool)
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

    if unequipCallback then
        unequipCallback()
        unequipCallback = nil
    end

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
