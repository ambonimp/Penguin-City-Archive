local DailyRewardsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Maid = require(Paths.Packages.maid)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local RewardsController = require(Paths.Client.Rewards.RewardsController)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local ItemDisplay = require(Paths.Client.UI.Elements.ItemDisplay)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Images = require(Paths.Shared.Images.Images)
local TableUtil = require(Paths.Shared.Utils.TableUtil)

local screenGui: ScreenGui = Ui.DailyRewards
local backgroundClone: ImageLabel
local isOpen = false
local openCallbacks: { () -> () } = {}

function DailyRewardsScreen.Init()
    -- Register UIState
    do
        local function enter()
            DailyRewardsScreen.open()
        end

        local function exit()
            DailyRewardsScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.DailyRewards, enter, exit)
    end

    -- Setup Background
    local background: ImageLabel = screenGui.Container.Background
    background.Days.Day.Visible = false

    backgroundClone = background:Clone()
    DailyRewardsScreen.setup(background, Maid.new(), true)

    -- Init Screen
    ScreenUtil.outUp(screenGui.Container)
    task.delay(1, function()
        screenGui.Enabled = true
    end)
end

function DailyRewardsScreen.setup(background: ImageLabel, maid: typeof(Maid.new()), isUi: boolean)
    -- Hoist
    local update: () -> ()
    local displayDays: (days: number?) -> ()

    local currentDisplayingDay = 1
    local isAttemptingClaim = false

    -- Button
    local canClaim = true
    local claimButton = KeyboardButton.new()
    claimButton:Mount(background.Button, true)
    claimButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen, true)
    claimButton:SetText("Claim Reward", true)
    claimButton.Pressed:Connect(function()
        if canClaim then
            -- RETURN: Attempting claim
            if isAttemptingClaim then
                return
            end

            isAttemptingClaim = true
            local claimAssume = RewardsController.claimDailyStreakRequest()

            task.wait()

            update()
            displayDays(currentDisplayingDay)

            local function afterClaim()
                isAttemptingClaim = false
                update()
            end
            claimAssume:Then(afterClaim):Else(afterClaim)
        else
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.DailyRewards)
        end
    end)

    -- Text Labels
    local streak: TextLabel = background.Streak
    local bestStreak: TextLabel = background.BestStreak
    local nextReward: TextLabel = background.NextReward

    -- Days
    local displayDaysMaid = Maid.new()
    maid:GiveTask(displayDaysMaid)

    function displayDays(day: number?)
        day = day or 1

        currentDisplayingDay = day
        displayDaysMaid:Cleanup()

        local lowestDay = (math.ceil(day / 5) - 1) * 5 + 1
        local currentDailyStreak = RewardsController.getCurrentDailyStreak()
        for dayNum = lowestDay, lowestDay + 4 do
            local holder: Frame = background.Days.Day:Clone()
            holder.Visible = true
            holder.LayoutOrder = dayNum
            holder.Parent = background.Days
            displayDaysMaid:GiveTask(holder)

            local reward = RewardsUtil.getDailyStreakReward(dayNum)
            local rewardText = reward.Coins and ("%s Coins"):format(StringUtil.commaValue(reward.Coins))
                or reward.Gift and ("%s Gift"):format(reward.Gift)
                or "undefined"
            local rewardIcon = reward.Coins and Images.Coins.Coin or ""
            local rewardImage = reward.Icon or ""
            local rewardColor = reward.Color

            local itemDisplay = ItemDisplay.new()
            itemDisplay:Mount(holder, true)
            itemDisplay:SetTitle(("Day %s"):format(StringUtil.commaValue(dayNum)))
            itemDisplay:SetText(rewardText)
            itemDisplay:SetTextIcon(rewardIcon)
            itemDisplay:SetImage(rewardImage)
            itemDisplay:SetBorderColor(rewardColor)
            displayDaysMaid:GiveTask(itemDisplay)

            if (not RewardsController.getUnclaimedDailyStreakDays()[dayNum] or isAttemptingClaim) and dayNum <= currentDailyStreak then
                itemDisplay:SetOverlay("Completed")
            end
        end
    end

    displayDays(1)
    table.insert(openCallbacks, function()
        displayDays(RewardsController.getCurrentDailyStreak())
    end)

    local leftButton = AnimatedButton.new(background.Left.ImageButton)
    leftButton.Pressed:Connect(function()
        displayDays(math.clamp(currentDisplayingDay - #RewardsConstants.DailyStreak.Rewards, 1, math.huge))
    end)
    maid:GiveTask(leftButton)

    local rightButton = AnimatedButton.new(background.Right.ImageButton)
    rightButton.Pressed:Connect(function()
        displayDays(math.clamp(currentDisplayingDay + #RewardsConstants.DailyStreak.Rewards, 1, math.huge))
    end)
    maid:GiveTask(rightButton)

    -- Updating
    local runWriteLoop = true
    maid:GiveTask(function()
        runWriteLoop = false
    end)

    function update()
        -- RETURN: Not visible
        if isUi and not isOpen then
            return
        end

        -- TextLabels
        streak.Text = ("Streak:<font size='65'> <b>%d</b></font>"):format(RewardsController.getCurrentDailyStreak())
        bestStreak.Text = ("Best Streak:<font size='65'> <b>%d</b></font>"):format(RewardsController.getBestDailyStreak())

        local timeUntilNextDailyStreakReward = RewardsController.getTimeUntilNextDailyStreakReward()
        nextReward.Text = timeUntilNextDailyStreakReward > 0
                and ("Next reward in <b>%s</b>"):format(TimeUtil.formatRelativeTime(timeUntilNextDailyStreakReward, 2))
            or "Claim your reward!"

        -- Button
        canClaim = not TableUtil.isEmpty(RewardsController.getUnclaimedDailyStreakDays()) and isAttemptingClaim == false
        if canClaim then
            claimButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
            claimButton:SetText("Claim Reward")
        else
            claimButton:SetColor(UIConstants.Colors.Buttons.CloseRed)
            claimButton:SetText("Close")
        end
    end
    task.spawn(function()
        while runWriteLoop do
            update()
            task.wait(1)
        end
    end)
    table.insert(openCallbacks, update)

    maid:GiveTask(RewardsController.DailyStreakUpdated:Connect(function()
        displayDays(RewardsController.getCurrentDailyStreak())
        update()
    end))
end

function DailyRewardsScreen.attachToPart(part: BasePart, face: Enum.NormalId)
    --todo
end

function DailyRewardsScreen.open()
    isOpen = true
    ScreenUtil.inDown(screenGui.Container)

    for _, callback in pairs(openCallbacks) do
        callback()
    end
end

function DailyRewardsScreen.close()
    isOpen = false
    ScreenUtil.outUp(screenGui.Container)
end

return DailyRewardsScreen
