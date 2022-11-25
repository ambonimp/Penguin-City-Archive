local DailyRewardsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Maid = require(Paths.Packages.maid)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local RewardsController: typeof(require(Paths.Client.Rewards.RewardsController))
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local ItemDisplay = require(Paths.Client.UI.Elements.ItemDisplay)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Images = require(Paths.Shared.Images.Images)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

local screenGui: ScreenGui = Ui.DailyRewards
local container: Frame = screenGui.Container
local backgroundClone: ImageLabel
local isOpen = false
local openCallbacks: { () -> () } = {}

function DailyRewardsScreen.Init()
    -- Dependencies
    RewardsController = require(Paths.Client.Rewards.RewardsController)

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.DailyRewards, {
        Boot = nil,
        Shutdown = nil,
        Maximize = DailyRewardsScreen.boot,
        Minimize = DailyRewardsScreen.shutdown,
    })

    -- Setup Background
    local background: ImageLabel = container.Background
    background.Days.Day.Visible = false

    backgroundClone = background:Clone()
    DailyRewardsScreen.setup(background, Maid.new(), true)

    -- Init Screen
    ScreenUtil.outUp(container)
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

    local function close()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.DailyRewards)
    end

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
            local claimAssume = RewardsController.claimDailyRewardRequest()

            update()
            displayDays(currentDisplayingDay)

            local function afterClaim()
                isAttemptingClaim = false
                update()
            end
            claimAssume:Then(afterClaim):Else(afterClaim)
        elseif isUi then
            close()
        end
    end)

    -- Closing
    UIController.registerStateCloseCallback(UIConstants.States.DailyRewards, close)

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
        local currentDailyReward = RewardsController.getCurrentDailyReward()
        for dayNum = lowestDay, lowestDay + 4 do
            local holder: Frame = background.Days.Day:Clone()
            holder.Visible = true
            holder.LayoutOrder = dayNum
            holder.Parent = background.Days
            displayDaysMaid:GiveTask(holder)

            local reward = RewardsUtil.getDailyRewardReward(dayNum)
            local rewardText = reward.Coins and ("%s Coins"):format(StringUtil.commaValue(reward.Coins))
                or reward.Gift and reward.Gift.Name
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

            if (not RewardsController.getUnclaimedDailyRewardDays()[dayNum] or isAttemptingClaim) and dayNum <= currentDailyReward then
                itemDisplay:SetOverlay("Completed")
            end
        end
    end

    displayDays(1)
    local function displayDaysOnOpen()
        displayDays(RewardsController.getCurrentDailyReward())
    end
    table.insert(openCallbacks, displayDaysOnOpen)
    displayDaysMaid:GiveTask(function()
        TableUtil.remove(openCallbacks, displayDaysOnOpen)
    end)

    local leftButton = AnimatedButton.new(background.Left.ImageButton)
    leftButton.Pressed:Connect(function()
        displayDays(math.clamp(currentDisplayingDay - #RewardsConstants.DailyReward.Rewards, 1, math.huge))
    end)
    maid:GiveTask(leftButton)

    local rightButton = AnimatedButton.new(background.Right.ImageButton)
    rightButton.Pressed:Connect(function()
        displayDays(math.clamp(currentDisplayingDay + #RewardsConstants.DailyReward.Rewards, 1, math.huge))
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
        streak.Text = ("Streak:<font size='65'> <b>%d</b></font>"):format(RewardsController.getCurrentDailyReward())
        bestStreak.Text = ("Best Streak:<font size='65'> <b>%d</b></font>"):format(RewardsController.getBestDailyReward())

        local timeUntilNextDailyRewardReward = RewardsController.getTimeUntilNextDailyRewardReward()
        nextReward.Text = timeUntilNextDailyRewardReward > 0
                and ("Next reward in <b>%s</b>"):format(TimeUtil.formatRelativeTime(timeUntilNextDailyRewardReward, 2))
            or "Claim your reward!"

        -- Button
        canClaim = not TableUtil.isEmpty(RewardsController.getUnclaimedDailyRewardDays()) and isAttemptingClaim == false
        if canClaim then
            claimButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
            claimButton:SetText("Claim Reward")
        else
            if isUi then
                claimButton:SetColor(UIConstants.Colors.Buttons.CloseRed)
                claimButton:SetText("Close")
            else
                claimButton:SetColor(UIConstants.Colors.Buttons.WaitOrange)
                claimButton:SetText("No Reward")
            end
        end
    end
    task.spawn(function()
        while runWriteLoop do
            update()
            task.wait(1)
        end
    end)
    table.insert(openCallbacks, update)

    maid:GiveTask(RewardsController.DailyRewardUpdated:Connect(function()
        displayDays(RewardsController.getCurrentDailyReward())
        update()
    end))
end

function DailyRewardsScreen.attachToPart(part: BasePart, face: Enum.NormalId)
    local maid = Maid.new()
    InstanceUtil.onDestroyed(part, function()
        if maid then
            maid:Destroy()
            maid = nil
        end
    end)

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Adornee = part
    surfaceGui.Face = face
    surfaceGui.Name = ("DailyRewards_%s"):format(part:GetFullName())
    surfaceGui.CanvasSize = Vector2.new(container.Size.X.Offset, container.Size.Y.Offset)
    surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    surfaceGui.Parent = Paths.UI
    maid:GiveTask(surfaceGui)

    local background = backgroundClone:Clone()
    background.Parent = surfaceGui
    DailyRewardsScreen.setup(background, maid, false)
end

function DailyRewardsScreen.boot()
    isOpen = true
    ScreenUtil.inDown(container)

    for _, callback in pairs(openCallbacks) do
        callback()
    end
end

function DailyRewardsScreen.shutdown()
    isOpen = false
    ScreenUtil.outUp(container)
end

return DailyRewardsScreen
