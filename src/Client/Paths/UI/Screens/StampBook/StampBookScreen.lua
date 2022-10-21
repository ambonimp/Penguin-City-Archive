local StampBookScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Button = require(Paths.Client.UI.Elements.Button)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Promise = require(Paths.Packages.promise)
local DataController = require(Paths.Client.DataController)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local Images = require(Paths.Shared.Images.Images)
local Maid = require(Paths.Packages.maid)
local StampConstants = require(Paths.Shared.Stamps.StampConstants)
local StampButton = require(Paths.Client.UI.Elements.StampButton)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Sound = require(Paths.Shared.Sound)
local PlayerIcon = require(Paths.Client.UI.Elements.PlayerIcon)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneController = require(Paths.Client.ZoneController)

local DEFAULT_CHAPTER = StampConstants.Chapters[1]
local SELECTED_TAB_SIZE = UDim2.new(1, 0, 0, 120)
local SELECTED_TAB_COLOR = Color3.fromRGB(247, 244, 227)
local TAB_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local BUTTONS = {
    Igloo = {
        Color = Color3.fromRGB(229, 142, 237),
        Icon = Images.Icons.Igloo,
    },
}

local screenGui: ScreenGui = Ui.StampBook
local closeButton = KeyboardButton.new()
local sealButton: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local previousPage: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local nextPage: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local cover: ImageLabel = screenGui.Container.Cover
local inside: Frame = screenGui.Container.Inside
local pageTitleText: TextLabel
local pageTitleImage: ImageLabel

local currentPlayer: Player?
local currentStampData = {
    OwnedStamps = {},
    StampBook = StampUtil.getStampBookDataDefaults(),
    IsLoading = true,
}
local loadedStampData = Promise.new(function() end) -- Intellisense hack
local currentView: "Cover" | "Inside"
local viewMaid = Maid.new()
local tabButtonsByChapter: { [StampConstants.Chapter]: typeof(Button.new(Instance.new("ImageButton"))) } = {}
local currentChapter: StampConstants.Chapter | nil
local currentPageNumber = 1
local currentMaxPageNumber = 1
local deselectedTabSize: UDim2
local deselectedTabColor: Color3
local totalStampsPerPage: number
local chapterMaid = Maid.new()

function StampBookScreen.Init()
    -- UI Setup
    do
        -- Close
        closeButton:Mount(screenGui.Container.CloseButton, true)
        closeButton:SetColor(UIConstants.Colors.Buttons.CloseRed)
        closeButton:SetIcon(Images.Icons.Close)
        closeButton:RoundOff()
        closeButton:Outline(UIConstants.Offsets.ButtonOutlineThickness, Color3.fromRGB(255, 255, 255))
        closeButton.Pressed:Connect(function()
            if currentView == "Inside" then
                Sound.play("CloseBook")
                StampBookScreen.openCover()
            else
                UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
            end
        end)

        -- Seal
        sealButton = AnimatedButton.new(cover.Seal.Button)
        sealButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
        sealButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)
        sealButton.Pressed:Connect(function()
            Sound.play("OpenBook")
            StampBookScreen.openInside()
        end)

        cover.Buttons.template.BackgroundTransparency = 1
        cover.Buttons.template.Visible = false

        cover.Stamps.BackgroundTransparency = 1
        cover.Stamps.template.Icon:Destroy()
        cover.Stamps.template.BackgroundTransparency = 1
        cover.Stamps.template.Visible = false
    end

    -- Register UIState
    do
        local function enter(data: table)
            StampBookScreen.open(data.Player)
        end

        local function exit()
            StampBookScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.StampBook, enter, exit)
    end
end

local function createCoverButton(layoutOrder: number)
    local holder: Frame = cover.Buttons.template:Clone()
    holder.Name = tostring(layoutOrder)
    holder.LayoutOrder = layoutOrder
    holder.Visible = true
    holder.Parent = cover.Buttons

    local button = KeyboardButton.new()
    button:RoundOff()
    button:Mount(holder.Button)

    viewMaid:GiveTask(holder)
    viewMaid:GiveTask(button)

    return button
end

function StampBookScreen.openCover()
    -- Manage Internals
    currentView = "Cover"
    cover.Visible = true
    inside.Visible = false
    viewMaid:Cleanup()

    -- Buttons
    do
        -- Igloo
        local iglooButton = createCoverButton(1)
        iglooButton:SetColor(BUTTONS.Igloo.Color)
        iglooButton:SetIcon(BUTTONS.Igloo.Icon)
        iglooButton.Pressed:Connect(function()
            local houseZone = ZoneUtil.houseZone(currentPlayer)
            ZoneController.teleportToRoomRequest(houseZone)

            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
        end)
    end

    -- Picture
    local playerIcon = PlayerIcon.new(currentPlayer)
    playerIcon:Mount(cover.Picture.IconHolder, true)
    viewMaid:GiveTask(playerIcon)

    -- Stamps
    if not currentStampData.IsLoading then
        for i, stampId in pairs(currentStampData.StampBook.CoverStampIds) do
            local stamp = StampUtil.getStampFromId(stampId)
            if stamp then
                local stampButton = StampButton.new(stamp)
                stampButton:GetButtonObject().LayoutOrder = i
                stampButton:Mount(cover.Stamps)

                viewMaid:GiveTask(stampButton)
            end
        end
    end

    -- Seal
    local seal = currentStampData.StampBook.Seal.Selected
    cover.Seal.Button.ImageColor3 = StampConstants.StampBook.Seals[seal].Color
    cover.Seal.Button.Icon.Image = StampConstants.StampBook.Seals[seal].Icon

    -- Pattern
    local pattern = currentStampData.StampBook.CoverPattern.Selected
    cover.Pattern.Image = Images.StampBook.Patterns[pattern]

    -- Text
    cover.PlayerName.Text = currentPlayer.DisplayName
    cover.PlayerName.TextColor3 = StampConstants.StampBook.TextColors[currentStampData.StampBook.TextColor.Selected]

    cover.TotalStamps.Text = ("TOTAL: %s/%s"):format(
        currentStampData.IsLoading and "?" or tostring(#currentStampData.OwnedStamps),
        StampUtil.getTotalStamps()
    )
    cover.TotalStamps.TextColor3 = StampConstants.StampBook.TextColors[currentStampData.StampBook.TextColor.Selected]
end

function StampBookScreen.openInside()
    -- Manage internals
    currentView = "Inside"
    cover.Visible = false
    inside.Visible = true
    viewMaid:Cleanup()

    StampBookScreen.openChapter(currentChapter or DEFAULT_CHAPTER)
end

local function selectTabButton(button: ImageButton)
    TweenUtil.tween(button, TAB_TWEEN_INFO, {
        Size = SELECTED_TAB_SIZE,
    })
    TweenUtil.tween(button.Body.Icon, TAB_TWEEN_INFO, {
        ImageColor3 = deselectedTabColor,
    })
    TweenUtil.tween(button.Body, TAB_TWEEN_INFO, {
        BackgroundColor3 = SELECTED_TAB_COLOR,
    })
    TweenUtil.tween(button.Left, TAB_TWEEN_INFO, {
        BackgroundColor3 = SELECTED_TAB_COLOR,
    })
end

local function deselectTabButton(button: ImageButton)
    TweenUtil.tween(button, TAB_TWEEN_INFO, {
        Size = deselectedTabSize,
    })
    TweenUtil.tween(button.Body.Icon, TAB_TWEEN_INFO, {
        ImageColor3 = Color3.fromRGB(255, 255, 255),
    })
    TweenUtil.tween(button.Body, TAB_TWEEN_INFO, {
        BackgroundColor3 = deselectedTabColor,
    })
    TweenUtil.tween(button.Left, TAB_TWEEN_INFO, {
        BackgroundColor3 = deselectedTabColor,
    })
end

function StampBookScreen.openChapter(chapter: StampConstants.Chapter, pageNumber: number?)
    -- New Chapter
    local chapterStructure = StampUtil.getChapterStructure(chapter)
    if currentChapter ~= chapter then
        -- Update Tab Buttons
        if currentChapter then
            deselectTabButton(tabButtonsByChapter[currentChapter]:GetButtonObject())
        end
        selectTabButton(tabButtonsByChapter[chapter]:GetButtonObject())

        -- Reset Page Number
        currentPageNumber = pageNumber or 1
        currentMaxPageNumber = StampUtil.getTotalChapterPages(chapterStructure, totalStampsPerPage)
    end
    currentPageNumber = pageNumber or currentPageNumber
    currentChapter = chapter

    chapterMaid:Cleanup()

    local chapterPage = StampUtil.getChapterPage(chapterStructure, totalStampsPerPage, currentPageNumber)

    -- Navigation
    inside.Chapter.Navigation.PageCount.Text = ("%d of %d"):format(currentPageNumber, currentMaxPageNumber)

    -- Title
    local displayInfo = chapterStructure.Display[chapterPage.Key]
    if displayInfo.ImageId then
        -- WARN: Missing width
        local width = StampConstants.TitleIconWidth[displayInfo.ImageId]
        if width then
            pageTitleImage.Size = UDim2.new(0, width, 1, 0)
        else
            warn(("StampConstants.TitleIconWidth missing for %q (%s)"):format(displayInfo.ImageId, chapterPage.Key))
        end

        pageTitleImage.Image = displayInfo.ImageId
    else
        pageTitleText.Text = displayInfo.Text
    end
    pageTitleImage.Visible = displayInfo.ImageId and true or false
    pageTitleText.Visible = not pageTitleImage.Visible

    -- Stamp Count
    inside.Chapter.StampCount.Text = ("?/%d Stamps"):format(#chapterStructure.Layout[chapterPage.Key]) --TODO Get total owned stamps

    -- Pattern
    --todo

    -- Stamps
    for i, stamp in pairs(chapterPage.Stamps) do
        local stampButton = StampButton.new(stamp)
        local buttonObject: ImageButton = stampButton:GetButtonObject()

        buttonObject.LayoutOrder = i
        buttonObject.Parent = inside.Chapter.Stamps

        chapterMaid:GiveTask(stampButton)
    end
end

function StampBookScreen.open(player: Player)
    -- WARN: No player?!
    if not player then
        warn("No player?!")
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
        return
    end

    -- Init state
    currentPlayer = player
    currentStampData = {
        OwnedStamps = {},
        StampBook = StampUtil.getStampBookDataDefaults(),
        IsLoading = true,
    }

    -- Open Cover
    StampBookScreen.openCover()

    -- reset tab buttons
    for _, tabButton in pairs(tabButtonsByChapter) do
        deselectTabButton(tabButton:GetButtonObject())
    end

    -- Load State
    loadedStampData = Promise.new(function(resolve, _reject, _onCancel)
        local stampData = player == Players.LocalPlayer and DataController.get("Stamps") or DataController.getPlayer(player, "Stamps")
        currentStampData = stampData
        resolve(currentStampData)
    end)

    loadedStampData:andThen(function()
        if currentView == "Cover" then
            StampBookScreen.openCover()
        elseif currentView == "Inside" then
            StampBookScreen.openInside()
        end
    end)

    screenGui.Enabled = true
end

function StampBookScreen.close()
    screenGui.Enabled = false

    currentChapter = nil
end

-- Setup UI
do
    -- Inside Tabs
    local tabs: Frame = inside.Tabs
    tabs.BackgroundTransparency = 1

    local tabsTemplate: ImageButton = tabs.template
    tabsTemplate.Visible = false

    deselectedTabSize = tabsTemplate.Size
    deselectedTabColor = tabsTemplate.Body.BackgroundColor3
    for i, chapter in pairs(StampConstants.Chapters) do
        local chapterTab = tabsTemplate:Clone()
        chapterTab.Name = chapter.DisplayName
        chapterTab.LayoutOrder = i
        chapterTab.Visible = true
        chapterTab.Parent = tabs

        chapterTab.Body.Icon.Image = chapter.Icon

        local chapterTabButton = Button.new(chapterTab)
        chapterTabButton.Pressed:Connect(function()
            Sound.play("PageTurn")
            StampBookScreen.openChapter(chapter)
        end)
        tabButtonsByChapter[chapter] = chapterTabButton
    end

    -- Chapter
    local chapterFrame: ImageLabel = inside.Chapter
    SELECTED_TAB_COLOR = chapterFrame.ImageColor3

    local stamps: Frame = inside.Chapter.Stamps
    stamps.BackgroundTransparency = 1

    local stampsUIGridLayout: UIGridLayout = stamps.UIGridLayout
    totalStampsPerPage = math.round((1 / stampsUIGridLayout.CellSize.X.Scale) * (1 / stampsUIGridLayout.CellSize.Y.Scale))

    local navigation: Frame = chapterFrame.Navigation
    previousPage = AnimatedButton.new(navigation.Left)
    previousPage.Pressed:Connect(function()
        -- RETURN: No previous page
        if currentPageNumber == 1 then
            return
        end

        Sound.play("PageTurn")
        StampBookScreen.openChapter(currentChapter, math.clamp(currentPageNumber - 1, 1, currentMaxPageNumber))
    end)

    nextPage = AnimatedButton.new(navigation.Right)
    nextPage.Pressed:Connect(function()
        -- RETURN: No next page
        if currentPageNumber == currentMaxPageNumber then
            return
        end

        Sound.play("PageTurn")
        StampBookScreen.openChapter(currentChapter, math.clamp(currentPageNumber + 1, 1, currentMaxPageNumber))
    end)

    pageTitleText = chapterFrame.Title.TextLabel
    pageTitleImage = chapterFrame.Title.ImageLabel
end

return StampBookScreen
