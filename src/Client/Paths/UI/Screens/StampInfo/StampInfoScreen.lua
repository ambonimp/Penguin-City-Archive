local StampInfoScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Packages.maid)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local StampButton = require(Paths.Client.UI.Elements.StampButton)
local StampConstants = require(Paths.Shared.Stamps.StampConstants)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)

local screenGui: ScreenGui = Ui.StampInfo
local containerFrame: Frame = screenGui.Container
local contents: Frame = containerFrame.Contents
local tiersFrame: Frame = contents.Tiers
local openMaid = Maid.new()
local isOpen = false

local closeButton = ExitButton.new()
local titleLabel: TextLabel = containerFrame.Title
local stampHolder: Frame = contents.Stamp.StampHolder
local descriptionLabel: TextLabel = contents.Stamp.Description
local bronzeTierLabel: TextLabel = tiersFrame.Bronze
local silverTierLabel: TextLabel = tiersFrame.Silver
local goldTierLabel: TextLabel = tiersFrame.Gold
local currentTierLabel: TextLabel = tiersFrame.Current

function StampInfoScreen.open(stampId: string, progress: number?)
    openMaid:Cleanup()

    if not isOpen then
        ScreenUtil.inDown(containerFrame)
        screenGui.Enabled = true
        isOpen = true
    end

    -- ERROR: Bad StampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        error(("Bad StampId %q"):format(stampId))
    end
    progress = StampUtil.calculateProgressNumber(stamp, progress)

    -- Basics
    titleLabel.Text = stamp.DisplayName
    descriptionLabel.Text = stamp.Description

    local stampButton = StampButton.new(stamp, {
        Progress = progress,
    })
    stampButton:Mount(stampHolder, true)
    openMaid:GiveTask(stampButton)

    -- Tiers
    tiersFrame.Visible = stamp.IsTiered
    if stamp.IsTiered then
        bronzeTierLabel.Text = ("Bronze | %d"):format(stamp.Tiers.Bronze)
        silverTierLabel.Text = ("Silver | %d"):format(stamp.Tiers.Silver)
        goldTierLabel.Text = ("Gold | %d"):format(stamp.Tiers.Gold)
        currentTierLabel.Text = ("%s (%d)"):format(StampUtil.getTierFromProgress(stamp, progress), progress)
    end
end

function StampInfoScreen.close()
    if isOpen then
        ScreenUtil.outUp(containerFrame)
        isOpen = false
    end
end

-- Close Button
do
    closeButton:Mount(containerFrame.CloseButton, true)
    closeButton.Pressed:Connect(function()
        if isOpen then
            StampInfoScreen.close()
        end
    end)
end

return StampInfoScreen
