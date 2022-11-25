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
local Sound = require(Paths.Shared.Sound)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

local BUTTON_PROPERTIES = {
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.9, 0.9),
}
local UNFURLED_MAP_PROPERTIES = {
    Position = UDim2.fromScale(0.75, 0.5),
    Size = UDim2.fromScale(1.5, 0.9),
}

local uiStateMachine = UIController.getStateMachine()

local screenGui: ScreenGui = Ui.HUD
local buttons: {
    Left: { typeof(AnimatedButton.new(Instance.new("ImageButton"))) },
    Right: { typeof(AnimatedButton.new(Instance.new("ImageButton"))) },
} =
    {
        Left = {},
        Right = {},
    }
local openCallbacks: { () -> () } = {}
local closeCallbacks: { () -> () } = {}

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

local function party(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Party

    --!!temp
    button.Pressed:Connect(function()
        Sound.play("ExtraLife")
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

local function createAnimatedButton(frame: Frame, _alignment: "Left" | "Right")
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
        table.insert(buttons.Left, createAnimatedButton(screenGui.Left.Buttons["1"], "Left"))
        table.insert(buttons.Left, createAnimatedButton(screenGui.Left.Buttons["2"], "Left"))
        table.insert(buttons.Left, createAnimatedButton(screenGui.Left.Buttons["3"], "Left"))
        table.insert(buttons.Right, createAnimatedButton(screenGui.Right.Buttons["1"], "Right"))
        table.insert(buttons.Right, createAnimatedButton(screenGui.Right.Buttons["2"], "Right"))
        table.insert(buttons.Right, createAnimatedButton(screenGui.Right.Buttons["3"], "Right"))
        table.insert(buttons.Right, createAnimatedButton(screenGui.Right.Buttons["4"], "Right"))

        -- Setup
        local mapButton = buttons.Left[3]
        local iglooButton = buttons.Right[1]
        inventoryButton = buttons.Right[4]

        dailyRewards(buttons.Left[1])
        party(buttons.Left[2])
        map(mapButton)
        igloo(iglooButton)
        stampBook(buttons.Right[2])
        clothing(buttons.Right[3])
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

    ScreenUtil.inRight(screenGui.Left)
    ScreenUtil.inLeft(screenGui.Right)
end

function HUDScreen.minimize()
    for _, callback in pairs(closeCallbacks) do
        task.spawn(callback)
    end

    ScreenUtil.outLeft(screenGui.Left)
    ScreenUtil.outRight(screenGui.Right)
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

screenGui.Enabled = true

return HUDScreen
