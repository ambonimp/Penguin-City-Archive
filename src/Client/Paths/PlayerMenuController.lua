--[[
    Controls the pop-up radial menus that appear on player characters
]]
local PlayerMenuController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InputController = require(Paths.Client.Input.InputController)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local Maid = require(Paths.Shared.Maid)
local RadialMenu = require(Paths.Client.UI.Elements.RadialMenu)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Images = require(Paths.Shared.Images.Images)
local StampController = require(Paths.Client.StampController)
local Sound = require(Paths.Shared.Sound)
local ButtonUtil = require(Paths.Client.UI.Utils.ButtonUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local ToolController = require(Paths.Client.Tools.ToolController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

local RAYCAST_LENGTH = 200
local RAYCAST_PARAMS = {
    FilterType = Enum.RaycastFilterType.Blacklist,
}
local RADIAL_MENU_SCALE = 0.25

local cursorDownPlayer: Player?
local cachedPlayer: Player?
local cacheMaid = Maid.new()

local function createBillboardGui()
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlayerMenu"
    billboardGui.Active = true
    billboardGui.AlwaysOnTop = true
    billboardGui.ClipsDescendants = true
    billboardGui.LightInfluence = 0
    billboardGui.Size = UDim2.fromScale(11, 11)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    return billboardGui
end

local function setupRadialButtons(player: Player, radialMenu: typeof(RadialMenu.new()))
    -- Stamps
    local stampsButton = radialMenu:AddButton() :: KeyboardButton.KeyboardButton
    stampsButton:RoundOff()
    ButtonUtil.paintStamps(stampsButton)
    stampsButton.Pressed:Connect(function()
        StampController.openStampBook(player)
    end)

    -- Igloo
    local iglooButton = radialMenu:AddButton() :: KeyboardButton.KeyboardButton
    iglooButton:RoundOff()
    ButtonUtil.paintIgloo(iglooButton)
    iglooButton.Pressed:Connect(function()
        local houseZone = ZoneUtil.houseInteriorZone(player)
        ZoneController.teleportToRoomRequest(houseZone, {
            TravelMethod = ZoneConstants.TravelMethod.PlayerMenu,
        })
    end)

    -- Close
    local closeButton = radialMenu:AddButton() :: KeyboardButton.KeyboardButton
    closeButton:RoundOff()
    closeButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    closeButton:SetIcon(Images.Icons.Close)
    closeButton.Pressed:Connect(PlayerMenuController.close)
end

function PlayerMenuController.clickedPlayer(player: Player)
    -- RETURN: Is local player!
    if player == Players.LocalPlayer then
        return
    end

    -- RETURN: We have a tool equipped
    if ToolController.hasToolEquipped() then
        return
    end

    -- EDGE CASE: Matches our cached player
    if cachedPlayer == player then
        PlayerMenuController.close()
        return
    end

    -- Cleanup old
    if cachedPlayer then
        PlayerMenuController.close()
    end

    -- RETURN: No humanoid root part
    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

    -- Open menu!
    Sound.play("RadialMenuOpen")

    cachedPlayer = player

    -- Create Radial Menu + mount
    local billboardGui = createBillboardGui()
    billboardGui.Adornee = humanoidRootPart
    billboardGui.Parent = Paths.UI

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.fromScale(1, 1)
    containerFrame.BackgroundTransparency = 1
    containerFrame.Parent = billboardGui

    local radialMenu = RadialMenu.new()
    radialMenu:SetScale(RADIAL_MENU_SCALE)
    radialMenu:Mount(containerFrame)

    setupRadialButtons(player, radialMenu)

    radialMenu:Open()

    cacheMaid:GiveTask(function()
        radialMenu:Close():andThen(function()
            billboardGui:Destroy()
            radialMenu:Destroy()
        end)
    end)
end

function PlayerMenuController.close()
    cachedPlayer = nil
    cacheMaid:Cleanup()
end

local function onCursorDown()
    local raycastResult = RaycastUtil.raycastMouse(RAYCAST_PARAMS, RAYCAST_LENGTH)
    cursorDownPlayer = raycastResult and CharacterUtil.getPlayerFromCharacterPart(raycastResult.Instance)
end

local function onCursorUp(gameProcessedEvent)
    -- RETURN: Doing something else
    if gameProcessedEvent then
        return
    end

    -- RETURN: WorldUI are disabled
    if not InteractionController.isEnabled() then
        return
    end

    -- RETURN: Clicked on an interaction
    local interactionIsActive, interactionLastActiveAt = InteractionController.isActive()
    if interactionIsActive or os.clock() - interactionLastActiveAt < 0.2 then
        return
    end

    local raycastResult = RaycastUtil.raycastMouse(RAYCAST_PARAMS, RAYCAST_LENGTH)
    local player = raycastResult and CharacterUtil.getPlayerFromCharacterPart(raycastResult.Instance)

    if player and player == cursorDownPlayer then
        PlayerMenuController.clickedPlayer(player)
    else
        PlayerMenuController.close()
    end
end

-- Listen for input
do
    InputController.CursorDown:Connect(onCursorDown)
    InputController.CursorUp:Connect(onCursorUp)
end

return PlayerMenuController
