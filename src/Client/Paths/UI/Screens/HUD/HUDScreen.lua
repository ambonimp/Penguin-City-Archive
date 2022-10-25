local HUDScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local Images = require(Paths.Shared.Images.Images)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Sound = require(Paths.Shared.Sound)

local screenGui: ScreenGui = Ui.HUD
local buttons: {
    Left: { typeof(AnimatedButton.new(Instance.new("ImageButton"))) },
    Right: { typeof(AnimatedButton.new(Instance.new("ImageButton"))) },
} =
    {
        Left = {},
        Right = {},
    }

local function isIglooButtonEdit()
    -- FALSE: Not in a house
    local houseOwner = ZoneUtil.getHouseZoneOwner(ZoneController.getCurrentZone())
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
            UIController.getStateMachine():Push(UIConstants.States.HouseEditor)
        else
            ZoneController.teleportToRoomRequest(ZoneController.getHouseZone())
        end
    end)
end

local function stampBook(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.StampBook

    --!!temp
    button.Pressed:Connect(function()
        Sound.play("OpenBook")
    end)
end

local function inventory(button: AnimatedButton.AnimatedButton)
    button:GetButtonObject().Image = Images.ButtonIcons.Inventory
    button.Pressed:Connect(function()
        UIController.getStateMachine():Push(UIConstants.States.CharacterEditor)
    end)
end

local function createButton(frame: Frame, _alignment: "Left" | "Right")
    local imageButton = Instance.new("ImageButton")
    imageButton.Size = UDim2.fromScale(0.9, 0.9)
    imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    imageButton.Position = UDim2.fromScale(0.5, 0.5)
    imageButton.BackgroundTransparency = 1
    imageButton.ScaleType = Enum.ScaleType.Fit
    imageButton.Parent = frame

    local button = AnimatedButton.new(imageButton)
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
        table.insert(buttons.Left, createButton(screenGui.Left.Buttons["1"], "Left"))
        table.insert(buttons.Left, createButton(screenGui.Left.Buttons["2"], "Left"))
        table.insert(buttons.Right, createButton(screenGui.Right.Buttons["1"], "Right"))
        table.insert(buttons.Right, createButton(screenGui.Right.Buttons["2"], "Right"))
        table.insert(buttons.Right, createButton(screenGui.Right.Buttons["3"], "Right"))

        -- Setup
        local iglooButton = buttons.Right[1]

        party(buttons.Left[1])
        map(buttons.Left[2])
        igloo(iglooButton)
        stampBook(buttons.Right[2])
        inventory(buttons.Right[3])

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
    end

    -- Register UIState
    do
        local isInState = true

        local function enter()
            -- RETURN: Already entered
            if isInState then
                return
            end
            isInState = true

            HUDScreen.open()
        end

        local function exit()
            -- RETURN: Not in state
            if not isInState then
                return
            end
            isInState = false

            HUDScreen.close()
        end

        local function readState()
            if UIUtil.getPseudoState(UIConstants.States.HUD, UIController.getStateMachine()) then
                enter()
            else
                exit()
            end
        end

        UIController.getStateMachine():RegisterGlobalCallback(readState)
        readState()
    end
end

function HUDScreen.open()
    screenGui.Enabled = true
end

function HUDScreen.close()
    screenGui.Enabled = false
end

return HUDScreen
