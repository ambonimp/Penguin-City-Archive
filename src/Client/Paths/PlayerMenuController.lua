--[[
    Controls the pop-up radial menus that appear on player characters
]]
local PlayerMenuController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InputController = require(Paths.Client.Input.InputController)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local Maid = require(Paths.Packages.maid)
local RadialMenu = require(Paths.Client.UI.Elements.RadialMenu)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Images = require(Paths.Shared.Images.Images)
local StampController = require(Paths.Client.StampController)

local RAYCAST_LENGTH = 200
local RAYCAST_PARAMS = {
    FilterType = Enum.RaycastFilterType.Blacklist,
}

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
    billboardGui.Size = UDim2.fromScale(10, 10)
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    return billboardGui
end

local function setupRadialButtons(player: Player, radialMenu: typeof(RadialMenu.new()))
    -- Stamps
    local stampsButton = radialMenu:AddButton()
    stampsButton:RoundOff()
    stampsButton:SetColor(UIConstants.Colors.Buttons.StampBeige, true)
    stampsButton:SetIcon(Images.ButtonIcons.StampBook)
    stampsButton.Pressed:Connect(function()
        StampController.openStampBook(player)
    end)

    -- Close
    local closeButton = radialMenu:AddButton()
    closeButton:RoundOff()
    closeButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    closeButton:SetIcon(Images.Icons.Close)
    closeButton.Pressed:Connect(PlayerMenuController.close)
end

function PlayerMenuController.clickedPlayer(player: Player)
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
    radialMenu:Mount(containerFrame)

    setupRadialButtons(player, radialMenu)

    cacheMaid:GiveTask(billboardGui)
    cacheMaid:GiveTask(radialMenu)
end

function PlayerMenuController.close()
    cachedPlayer = nil
    cacheMaid:Cleanup()
end

local function onCursorDown()
    local raycastResult = RaycastUtil.raycastMouse(RAYCAST_PARAMS, RAYCAST_LENGTH)
    cursorDownPlayer = raycastResult and CharacterUtil.getPlayerFromCharacterPart(raycastResult.Instance)
end

local function onCursorUp()
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
