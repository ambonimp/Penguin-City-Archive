local PlotChangerScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Button = require(Paths.Client.UI.Elements.Button)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local CameraController = require(Paths.Client.CameraController)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)

local CAMERA_TWEEN_INFO = TweenInfo.new(0.2)
local PLOT_OWNED_CAMERA_OFFSET = CFrame.new(0, 0, 42)
local NO_PLOT_OWNED_CAMERA_OFFSET = CFrame.new(0, 8, 35)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local plots = workspace.Rooms.Neighborhood.HousingPlots
local total = #plots:GetChildren()
local previewingIndex: number

local screenGui: ScreenGui = Paths.UI.Housing
local frame: Frame = screenGui.PlotChanger
local ownerLabel: TextLabel = frame.Owner
local setButtonContainer: Frame = frame.ChangePlot

local uiStateMachine = UIController.getStateMachine()

local function preview()
    local plot = plots:FindFirstChild(previewingIndex :: string)

    local ownerId: number? = plot:GetAttribute(HousingConstants.PlotOwner)
    if ownerId then
        ownerLabel.Text = StringUtil.possessiveName(Players:GetPlayerByUserId(ownerId).DisplayName) .. " house"
        setButtonContainer.Visible = false

        CameraUtil.lookAt(camera, plot.WorldPivot, PLOT_OWNED_CAMERA_OFFSET, CAMERA_TWEEN_INFO)
    else
        ownerLabel.Text = "Empty"
        setButtonContainer.Visible = true

        CameraUtil.lookAt(camera, plot.WorldPivot, NO_PLOT_OWNED_CAMERA_OFFSET, CAMERA_TWEEN_INFO)
    end
end

-- Register UIState
do
    local function open(data)
        previewingIndex = tonumber(data.PlotAt.Name)
        preview()

        CharacterUtil.freeze(player.Character)
        ScreenUtil.sizeIn(frame)
    end

    local function close()
        CameraController.setPlayerControl()
        CharacterUtil.unfreeze(player.Character)

        ScreenUtil.sizeOut(frame)
    end
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.PlotChanger, open, close)
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new()
    exitButton:Mount(frame.ExitButton, true)
    exitButton.Pressed:Connect(function()
        uiStateMachine:Pop()
    end)
end

do
    Button.new(frame.Next).Pressed:Connect(function()
        if previewingIndex + 1 > total then
            previewingIndex = 1
        else
            previewingIndex += 1
        end

        preview()
    end)

    Button.new(frame.Previous).Pressed:Connect(function()
        if previewingIndex - 1 < 1 then
            previewingIndex = total
        else
            previewingIndex -= 1
        end

        preview()
    end)

    local changePlotButton = WideButton.green("Change Plot")
    changePlotButton.Pressed:Connect(function()
        local plot: Model = plots[previewingIndex]

        if plot and not plot:GetAttribute(HousingConstants.PlotOwner) then
            Remotes.fireServer("ChangePlot", plot) -- TODO: Teleport them infront of new plot
            uiStateMachine:PopTo(UIConstants.States.Nothing) --  TODO: Set this to the HUD when it's complete
        end
    end)
    changePlotButton:Mount(setButtonContainer, true)
end

return PlotChangerScreen
