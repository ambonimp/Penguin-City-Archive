local MobileButtons = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)
local CharacterController = require(Paths.Client.Character.CharacterController)
local Images = require(Paths.Shared.Images.Images)
local MobileButtonsScreen = Ui.MobileButtons
local BackgroundFrame = MobileButtonsScreen.Background
local Button = require(Paths.Client.UI.Elements.Button)

local function getJumpButtonPositionAndSize()
    if Ui:FindFirstChild("TouchGui") then
        return Ui.TouchGui.TouchControlFrame.JumpButton.AbsolutePosition, Ui.TouchGui.TouchControlFrame.JumpButton.AbsoluteSize
    end
end

local function getMobileButton(icon: string, position: Vector2, size: Vector2)
    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.Size = UDim2.fromOffset(size.X, size.Y)
    ImageLabel.Position = UDim2.fromOffset(position.X, position.Y)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Image = Images.Icons.MobileButton
    ImageLabel.ImageTransparency = 0.35
    ImageLabel.ScaleType = Enum.ScaleType.Fit

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageButton.Size = UDim2.new(0.6, 0, 0.6, 0)
    ImageButton.Image = icon
    ImageButton.ImageTransparency = 0.35
    ImageButton.BackgroundTransparency = 1
    ImageButton.ScaleType = Enum.ScaleType.Fit
    ImageButton.Parent = ImageLabel

    ImageLabel.Parent = BackgroundFrame
    return ImageLabel, ImageButton
end

if DeviceUtil.isMobile then
    --sprint button
    local position, size = getJumpButtonPositionAndSize()
    position -= Vector2.new(0, size.X * 0.95)
    size = Vector2.new(size.X * 0.8, size.Y * 0.8)

    local sprintLabel, sprintButton = getMobileButton(Images.Icons.Sprint, position, size)
    local SprintButtonLoaded = Button.new(sprintButton)

    SprintButtonLoaded.Pressed:Connect(function()
        local isSprinting = CharacterController.toggleSprint()

        if isSprinting then
            sprintButton.ImageColor3 = Color3.new(0.450980, 1, 0)
        else
            sprintButton.ImageColor3 = Color3.new(1, 1, 1)
        end
    end)

    function MobileButtons.maximize()
        sprintLabel.Visible = true
    end

    function MobileButtons.minimize()
        sprintLabel.Visible = false
    end
else
    MobileButtonsScreen:Destroy()
end

return MobileButtons
