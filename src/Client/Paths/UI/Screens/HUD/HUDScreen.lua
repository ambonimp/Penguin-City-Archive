local HUDScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Images = require(Paths.Shared.Images.Images)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ToolController = require(Paths.Client.Tools.ToolController)
local Maid = require(Paths.Packages.maid)
local Widget = require(Paths.Client.UI.Elements.Widget)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)

local BUTTON_PROPERTIES = {
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.9, 0.9),
}
local UNFURLED_MAP_PROPERTIES = {
    Position = UDim2.fromScale(0.25, 0.5),
    Size = UDim2.fromScale(1.5, 0.9),
}

local uiStateMachine = UIController.getStateMachine()
local screenGui: ScreenGui = Ui.HUD
local openCallbacks: { () -> () } = {}
local closeCallbacks: { () -> () } = {}
local toolbarMaid = Maid.new()
local inventoryButton: AnimatedButton.AnimatedButton

local function isIglooButtonEdit()
    -- FALSE: Not in a house
    local houseOwner = ZoneUtil.getHouseInteriorZoneOwner(ZoneController.getCurrentZone())
    if not houseOwner then
        return
    end

    return ZoneController.hasEditPerms(houseOwner)
end

-------------------------------------------------------------------------------
-- Button Setup
-------------------------------------------------------------------------------

local function map(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.FoldedMap

    --!!temp
    button.Pressed:Connect(ZoneController.teleportToRandomRoom)
end

local function dailyRewards(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Rewards

    button.Pressed:Connect(function()
        UIController.getStateMachine():Push(UIConstants.States.DailyRewards)
    end)
end

local function igloo(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Igloo

    -- toggle edit functionality
    button.Pressed:Connect(function()
        if isIglooButtonEdit() then
            uiStateMachine:Push(UIConstants.States.HouseEditor, {
                InteriorPlot = uiStateMachine:GetData().InteriorPlot,
            })
        else
            ZoneController.teleportToRoomRequest(ZoneController.getLocalHouseInteriorZone())
        end
    end)
end

local function stampBook(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.StampBook

    button.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.StampBook, {
            Player = Players.LocalPlayer,
        })
    end)
end

local function clothing(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Shirt
    button.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.CharacterEditor)
    end)
end

local function inventory(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Inventory
    button.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.Inventory)
    end)
end

local function createAnimatedButton(frame: Frame)
    local imageButton = Instance.new("ImageButton")
    imageButton.Size = BUTTON_PROPERTIES.Size
    imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    imageButton.Position = BUTTON_PROPERTIES.Position
    imageButton.BackgroundTransparency = 1
    imageButton.ScaleType = Enum.ScaleType.Fit
    imageButton.Parent = frame

    local button = AnimatedButton.new(imageButton)
    button:SetPressAnimation(AnimatedButton.Animations.Squish)
    button:SetHoverAnimation(AnimatedButton.Animations.Nod)

    return button
end

-------------------------------------------------------------------------------
-- Tools
-------------------------------------------------------------------------------

local function updateToolbar()
    toolbarMaid:Cleanup()

    local itemHolderTemplate: Frame = screenGui.Bottom.itemHolder
    itemHolderTemplate.BackgroundTransparency = 1
    itemHolderTemplate.Visible = false

    -- Create a toolbar widget for each tool
    local holsteredTools = ToolController.getHolsteredTools()
    for i, tool in pairs(holsteredTools) do
        -- Holder
        local holder = itemHolderTemplate:Clone()
        holder.Name = tool.ToolId
        holder.LayoutOrder = i
        holder.Parent = screenGui.Bottom
        holder.Visible = true
        toolbarMaid:GiveTask(holder)

        -- Widget
        local toolWidget, closeButton = Widget.diverseWidgetFromTool(tool)
        toolWidget:Mount(holder)
        toolWidget.Pressed:Connect(function()
            -- Unequip
            local equippedTool = ToolController.getEquipped()
            if equippedTool then
                ToolController.unequip()
            end

            -- Equip
            if not (equippedTool and ToolUtil.toolsMatch(equippedTool, tool)) then
                ToolController.equipRequest(tool)
            end
        end)
        toolbarMaid:GiveTask(toolWidget)

        -- Close button
        toolbarMaid:GiveTask(closeButton.Pressed:Connect(function()
            ToolController.unholster(tool)
        end))
    end
end

ToolController.ToolHolstered:Connect(updateToolbar)
ToolController.ToolUnholstered:Connect(updateToolbar)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function HUDScreen.Init()
    -- Create Buttons
    do
        -- Make everyone invisible
        for _, descendant: GuiObject in pairs(screenGui:GetDescendants()) do
            if descendant:IsA("GuiObject") then
                descendant.BackgroundTransparency = 1
            end
        end

        -- Create Buttons
        local iglooButton = createAnimatedButton(screenGui.Right.Igloo)
        local clothingButton = createAnimatedButton(screenGui.Right.Clothing)
        local mapButton = createAnimatedButton(screenGui.Right.Map)
        local rewardsButton = createAnimatedButton(screenGui.Right.Rewards)
        local stampBookButton = createAnimatedButton(screenGui.Right.StampBook)
        inventoryButton = createAnimatedButton(screenGui.Bottom.Inventory)

        dailyRewards(rewardsButton)
        map(mapButton)
        igloo(iglooButton)
        stampBook(stampBookButton)
        clothing(clothingButton)
        inventory(inventoryButton)

        -- Igloo Button (toggle edit look)
        do
            local pencilImage = Instance.new("ImageLabel")
            pencilImage.Size = UDim2.fromScale(0.7, 0.7)
            pencilImage.AnchorPoint = Vector2.new(0.2, 0.8)
            pencilImage.Position = UDim2.fromScale(0.5, 0.5)
            pencilImage.BackgroundTransparency = 1
            pencilImage.ScaleType = Enum.ScaleType.Fit
            pencilImage.Image = Images.ButtonIcons.Pencil
            pencilImage.Parent = iglooButton:GetButtonObject()

            local function updateIgloo()
                if isIglooButtonEdit() then
                    pencilImage.Visible = true
                else
                    pencilImage.Visible = false
                end
            end

            ZoneController.ZoneChanged:Connect(updateIgloo)
            updateIgloo()
        end

        -- Map button (folded and open)
        do
            mapButton:SetHoverAnimation(nil)
            local buttonObject: ImageButton = mapButton:GetButtonObject()

            local function fold()
                buttonObject.Position = BUTTON_PROPERTIES.Position
                buttonObject.Size = BUTTON_PROPERTIES.Size
                buttonObject.Image = Images.ButtonIcons.FoldedMap
            end

            local function unfurl()
                buttonObject.Position = UNFURLED_MAP_PROPERTIES.Position
                buttonObject.Size = UNFURLED_MAP_PROPERTIES.Size
                buttonObject.Image = Images.ButtonIcons.Map
            end

            mapButton.InternalEnter:Connect(unfurl)
            mapButton.InternalLeave:Connect(fold)
            table.insert(openCallbacks, fold)

            fold()
        end
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.HUD, {
        Boot = nil,
        Shutdown = nil,
        Maximize = HUDScreen.maximize,
        Minimize = HUDScreen.minimize,
    })
end

function HUDScreen.getInventoryButton()
    return inventoryButton
end

function HUDScreen.maximize()
    for _, callback in pairs(openCallbacks) do
        task.spawn(callback)
    end

    ScreenUtil.inUp(screenGui.Bottom)
    ScreenUtil.inLeft(screenGui.Right)
end

function HUDScreen.minimize()
    for _, callback in pairs(closeCallbacks) do
        task.spawn(callback)
    end

    ScreenUtil.outDown(screenGui.Bottom)
    ScreenUtil.outRight(screenGui.Right)
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

screenGui.Enabled = true

return HUDScreen
