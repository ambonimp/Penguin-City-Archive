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
local RichTextUtil = require(Paths.Shared.Utils.RichTextUtil)

local RICH_TEXT_BRONZE = RichTextUtil.addTag(RichTextUtil.addTag("Bronze", "b"), "font", {
    RichTextUtil.getRGBTagContent(StampConstants.TierColors.Bronze),
})
local RICH_TEXT_SILVER = RichTextUtil.addTag(RichTextUtil.addTag("Silver", "b"), "font", {
    RichTextUtil.getRGBTagContent(StampConstants.TierColors.Silver),
})
local RICH_TEXT_GOLD = RichTextUtil.addTag(RichTextUtil.addTag("Gold", "b"), "font", {
    RichTextUtil.getRGBTagContent(StampConstants.TierColors.Gold),
})

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

    local currentTier = StampUtil.getTierFromProgress(stamp, progress)
    local useTier = stamp.IsTiered and currentTier or Stamps.StampTiers[1]

    -- Basics
    titleLabel.Text = stamp.DisplayName
    descriptionLabel.Text = stamp.IsTiered and stamp.Description[useTier] or stamp.Description

    local stampButton = StampButton.new(stamp, {
        Progress = progress,
    })
    stampButton:Mount(stampHolder, true)
    openMaid:GiveTask(stampButton)

    -- Tiers
    tiersFrame.Visible = stamp.IsTiered
    if stamp.IsTiered then
        bronzeTierLabel.Text = ("%s | %d"):format(RICH_TEXT_BRONZE, stamp.Tiers.Bronze)
        silverTierLabel.Text = ("%s | %d"):format(RICH_TEXT_SILVER, stamp.Tiers.Silver)
        goldTierLabel.Text = ("%s | %d"):format(RICH_TEXT_GOLD, stamp.Tiers.Gold)

        local currentText = currentTier == "Gold" and RICH_TEXT_GOLD
            or currentTier == "Silver" and RICH_TEXT_SILVER
            or currentTier == "Bronze" and RICH_TEXT_BRONZE
            or "-"
        currentTierLabel.Text = ("%s (%d)"):format(currentText, progress)
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
