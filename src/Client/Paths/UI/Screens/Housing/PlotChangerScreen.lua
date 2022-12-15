local PlotChangerScreen = {}
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local UIController = require(Paths.Client.UI.UIController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local TransitionFX = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Button = require(Paths.Client.UI.Elements.Button)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local CameraController = require(Paths.Client.CameraController)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local HousingController = require(Paths.Client.HousingController)

local CAMERA_TWEEN_INFO = TweenInfo.new(0.2)
local PLOT_OWNED_CAMERA_OFFSET = CFrame.new(0, 0, 42)
local NO_PLOT_OWNED_CAMERA_OFFSET = CFrame.new(0, 8, 35)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local plots = workspace.Rooms.Neighborhood.HousingPlots
local TOTAL_PLOTS = HousingConstants.Plots
local previewingIndex: number

local screenGui: ScreenGui = Paths.UI.PlotChanger
local frame: Frame = screenGui.PlotChanger
local ownerLabel: TextLabel = frame.Owner
local setButtonContainer: Frame = frame.ChangePlot
local currentPlayerPlot: Instance

local uiStateMachine = UIController.getStateMachine()

local function preview()
    local plot = plots:FindFirstChild(previewingIndex :: string)

    local ownerId: number? = plot:GetAttribute(HousingConstants.PlotOwner)
    if ownerId then
        ownerLabel.Text = StringUtil.possessiveName(Players:GetPlayerByUserId(ownerId).DisplayName) .. " house"
        setButtonContainer.Visible = false

        CameraUtil.lookAt(camera, plot.WorldPivot, PLOT_OWNED_CAMERA_OFFSET, CAMERA_TWEEN_INFO)

        if ownerId == player.UserId then
            currentPlayerPlot = plot
        end
    else
        ownerLabel.Text = "Empty"
        setButtonContainer.Visible = true

        CameraUtil.lookAt(camera, plot.WorldPivot, NO_PLOT_OWNED_CAMERA_OFFSET, CAMERA_TWEEN_INFO)
    end
end

-- Register UIState
do
    local function boot(data)
        previewingIndex = tonumber(data.PlotAt.Name)
        preview()
        screenGui.Enabled = true
        CharacterUtil.freeze(player.Character)
        ScreenUtil.sizeIn(frame)
    end

    local function shutdown()
        CameraController.setPlayerControl()
        CharacterUtil.unfreeze(player.Character)
        ScreenUtil.sizeOut(frame)
    end

    --uiStateMachine:RegisterStateCallbacks(UIConstants.States.PlotChanger, open, close)
    UIController.registerStateScreenCallbacks(UIConstants.States.PlotChanger, {
        Boot = boot,
        Shutdown = shutdown,
        Maximize = nil,
        Minimize = nil,
    })
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new(UIConstants.States.PlotChanger)
    exitButton:Mount(frame.ExitButton, true)
    exitButton.Pressed:Connect(function()
        uiStateMachine:PopTo(UIConstants.States.HUD)
    end)
end

do
    Button.new(frame.Next).Pressed:Connect(function()
        if previewingIndex + 1 > TOTAL_PLOTS then
            previewingIndex = 1
        else
            previewingIndex += 1
        end

        preview()
    end)

    Button.new(frame.Previous).Pressed:Connect(function()
        if previewingIndex - 1 < 1 then
            previewingIndex = TOTAL_PLOTS
        else
            previewingIndex -= 1
        end

        preview()
    end)

    local changePlotButton = WideButton.green("Change Plot")
    changePlotButton.Pressed:Connect(function()
        local plot: Model = plots[previewingIndex]

        if plot and not plot:GetAttribute(HousingConstants.PlotOwner) and plot ~= currentPlayerPlot then
            if currentPlayerPlot and currentPlayerPlot.Origin:FindFirstChild("IglooIcon") then
                currentPlayerPlot.Origin:FindFirstChild("IglooIcon").Enabled = false
            end
            uiStateMachine:PopTo(UIConstants.States.HUD)
            Remotes.fireServer("ChangePlot", plot)
            currentPlayerPlot = plot

            TransitionFX.blink(function()
                player.Character:PivotTo(currentPlayerPlot.Origin.CFrame * CFrame.new(0, player.Character:GetExtentsSize().Y * 0.8, -15))
                if currentPlayerPlot and currentPlayerPlot.Origin:FindFirstChild("IglooIcon") then
                    currentPlayerPlot.Origin:FindFirstChild("IglooIcon").Enabled = true
                end
            end)
        end
    end)
    changePlotButton:Mount(setButtonContainer, true)

    ZoneController.ZoneChanged:Connect(function(_oldZone: ZoneConstants.Zone, newZone: ZoneConstants.Zone)
        if newZone.ZoneType == "Neighborhood" then
            currentPlayerPlot = HousingController.getPlotFromOwner(player, HousingConstants.ExteriorType)

            if currentPlayerPlot and currentPlayerPlot.Origin:FindFirstChild("IglooIcon") then
                currentPlayerPlot.Origin:FindFirstChild("IglooIcon").Enabled = true
            end
        end
    end)
end

return PlotChangerScreen
