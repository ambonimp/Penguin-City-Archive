local StampBookScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Button = require(Paths.Client.UI.Elements.Button)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
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
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ButtonUtil = require(Paths.Client.UI.Utils.ButtonUtil)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanel)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local StampController = require(Paths.Client.StampController)
local UIActions = require(Paths.Client.UI.UIActions)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Remotes = require(Paths.Shared.Remotes)
local Widget = require(Paths.Client.UI.Elements.Widget)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)

local DEFAULT_CHAPTER = StampConstants.Chapters[1]
local SELECTED_TAB_SIZE = UDim2.new(1, 0, 0, 120)
local SELECTED_TAB_COLOR = Color3.fromRGB(247, 244, 227)
local TAB_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local EDIT_MODE_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local EDIT_MODE_CONTAINER_POSITION = UDim2.fromScale(0.6, 0.5)
local DEFAULT_CONTAINER_POSITION = UDim2.fromScale(0.5, 0.5)
local TABS = {
    CoverColor = "CoverColor",
    TextColor = "TextColor",
    Stamps = "Stamps",
    Seal = "Seal",
    Pattern = "Pattern",
}

local screenGui: ScreenGui = Ui.StampBook
local containerFrame: Frame = screenGui.Container
local closeButton = ExitButton.new()
local sealButton: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local previousPage: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local nextPage: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local cover: ImageLabel = containerFrame.Cover
local inside: Frame = containerFrame.Inside
local pageTitleText: TextLabel
local pageTitleImage: ImageLabel
local editPanel = SelectionPanel.new()

local currentPlayer: Player?
local currentStampData = {
    OwnedStamps = {},
    StampBook = StampUtil.getStampBookDataDefaults(),
    IsLoading = true,
}
local updatedStampBookData: { [string]: any } = {
    CoverStampIds = {},
} --!! Gets reset
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
local isEditing = false
local wasEditing = false -- For maximize/minimise
local readStampDataMaid = Maid.new()

-- Hoist
local function readStampData() end

local function toggleEditMode(forceEnabled: boolean?)
    -- RETURN: No change
    if forceEnabled ~= nil and forceEnabled == isEditing then
        return
    end
    wasEditing = isEditing
    isEditing = not isEditing

    -- Handle active/deactive
    if isEditing then
        ScreenUtil.inRight(editPanel:GetContainer())
        TweenUtil.tween(containerFrame, EDIT_MODE_TWEEN_INFO, {
            Position = EDIT_MODE_CONTAINER_POSITION,
        })
    else
        ScreenUtil.outLeft(editPanel:GetContainer())
        TweenUtil.tween(containerFrame, EDIT_MODE_TWEEN_INFO, {
            Position = DEFAULT_CONTAINER_POSITION,
        })
    end
end

local function addCoverStamp(stamp: Stamps.Stamp)
    -- RETURN: Too many
    if #updatedStampBookData.CoverStampIds >= StampConstants.MaxCoverStamps then
        return false
    end

    -- RETURN: Already added
    if table.find(updatedStampBookData.CoverStampIds, stamp.Id) then
        return false
    end

    -- RETURN: Not owned
    local progress = StampController.getProgress(stamp.Id, currentStampData.OwnedStamps)
    if stamp.IsTiered then
        local tier = StampUtil.getTierFromProgress(stamp, progress)
        if not tier then
            return false
        end
    else
        if progress == 0 then
            return false
        end
    end

    table.insert(updatedStampBookData.CoverStampIds, stamp.Id)

    local newData: { [string]: string } = {}
    for i, stampId in pairs(updatedStampBookData.CoverStampIds) do
        newData[tostring(i)] = stampId
    end
    currentStampData.StampBook.CoverStampIds = newData

    readStampData()

    return true
end

local function removeCoverStamp(stamp: Stamps.Stamp)
    -- RETURN: Not added
    local index = table.find(updatedStampBookData.CoverStampIds, stamp.Id)
    if not index then
        return false
    end

    table.remove(updatedStampBookData.CoverStampIds, index)

    local newData: { [string]: string } = {}
    for i, stampId in pairs(updatedStampBookData.CoverStampIds) do
        newData[tostring(i)] = stampId
    end
    currentStampData.StampBook.CoverStampIds = newData

    readStampData()

    return true
end

-- Updates the cover based on our StampBook data
function readStampData()
    readStampDataMaid:Cleanup()

    -- Stamps
    do
        editPanel:RemoveWidgets(TABS.Stamps)

        if not currentStampData.IsLoading then
            for i, stampId in pairs(updatedStampBookData.CoverStampIds) do
                local stamp = StampUtil.getStampFromId(stampId)
                if stamp then
                    local progress = StampController.getProgress(stamp.Id, currentStampData.OwnedStamps)

                    -- Holder
                    local holder: Frame = cover.Stamps.template:Clone()
                    holder.Name = stampId
                    holder.LayoutOrder = i
                    holder.Visible = true
                    holder.Parent = cover.Stamps
                    readStampDataMaid:GiveTask(holder)

                    -- Cover Button
                    local stampButton = StampButton.new(stamp, {
                        Progress = progress,
                    })
                    stampButton:Mount(holder)
                    stampButton.Pressed:Connect(function()
                        UIActions.showStampInfo(stampId, progress)
                    end)

                    readStampDataMaid:GiveTask(stampButton)

                    -- Widgets
                    local tier = stamp.IsTiered and StampUtil.getTierFromProgress(stamp, progress) or "Bronze"
                    local imageId = stamp.IsTiered and stamp.ImageId[tier] or stamp.ImageId

                    editPanel:AddWidgetConstructor(TABS.Stamps, stampId, false, function(parent, maid)
                        local widget = Widget.diverseWidget()
                        widget:SetIcon(imageId)
                        widget.Pressed:Connect(function()
                            removeCoverStamp(stamp)
                        end)

                        widget:Mount(parent)
                        maid:GiveTask(widget)

                        return widget
                    end)
                end
            end
        end

        editPanel:AddWidgetConstructor(TABS.Stamps, "Add", false, function(parent, maid)
            local widget = Widget.addWidget()
            widget.Pressed:Connect(function()
                StampBookScreen.openInside()
            end)

            widget:Mount(parent)
            maid:GiveTask(widget)

            return widget
        end)
    end

    -- Seal
    local seal = currentStampData.StampBook.Seal
    cover.Seal.Button.ImageColor3 = StampConstants.StampBook.Seal[seal].Color
    cover.Seal.Button.Icon.Image = StampConstants.StampBook.Seal[seal].Icon or ""
    cover.Seal.Button.Icon.ImageColor3 = StampConstants.StampBook.Seal[seal].IconColor or StampConstants.StampBook.Seal[seal].Color

    -- Pattern
    local pattern = currentStampData.StampBook.CoverPattern
    cover.Pattern.Image = Images.StampBook.Patterns[pattern]

    -- Cover
    local coverColor = currentStampData.StampBook.CoverColor
    local coverColors = StampConstants.StampBook.CoverColor[coverColor]
    cover.ImageColor3 = coverColors.Primary
    cover.StampIcon.ImageColor3 = coverColors.Secondary
    cover.StampIcon.StampCollection.TextColor3 = coverColors.Primary
    cover.StampIcon.StampCollection.UIStroke.Color = coverColors.Secondary

    -- Text
    cover.PlayerName.Text = currentPlayer.DisplayName
    cover.PlayerName.TextColor3 = StampConstants.StampBook.TextColor[currentStampData.StampBook.TextColor]

    cover.TotalStamps.Text = ("TOTAL: %s/%s"):format(
        currentStampData.IsLoading and "?" or tostring(TableUtil.length(currentStampData.OwnedStamps)),
        StampUtil.getTotalStamps()
    )
    cover.TotalStamps.TextColor3 = StampConstants.StampBook.TextColor[currentStampData.StampBook.TextColor]
end

function StampBookScreen.Init()
    local function close()
        if currentView == "Inside" then
            Sound.play("CloseBook")
            StampBookScreen.openCover()
        else
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
        end
    end

    -- UI Setup
    do
        -- Close
        closeButton:Mount(containerFrame.CloseButton, true)
        closeButton.Pressed:Connect(close)

        UIController.registerStateCloseCallback(UIConstants.States.StampBook, function()
            if isEditing then
                toggleEditMode(false)
            else
                close()
            end
        end)

        -- Seal
        sealButton = AnimatedButton.new(cover.Seal.Button)
        sealButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
        sealButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)
        sealButton.Pressed:Connect(function()
            Sound.play("OpenBook")
            toggleEditMode(false)
            StampBookScreen.openInside()
        end)

        cover.Buttons.template.BackgroundTransparency = 1
        cover.Buttons.template.Visible = false

        cover.Stamps.BackgroundTransparency = 1
        cover.Stamps.template.Icon:Destroy()
        cover.Stamps.template.BackgroundTransparency = 1
        cover.Stamps.template.Visible = false
    end

    -- Edit Panel Setup
    do
        editPanel:Mount(screenGui)
        editPanel:SetAlignment("Left")
        editPanel:SetSize(1)

        editPanel.ClosePressed:Connect(function()
            toggleEditMode(false)
        end)

        -- Cover Color
        editPanel:AddTab(TABS.CoverColor, Images.Icons.PaintBucket)
        for colorName, _color in pairs(StampConstants.StampBook.CoverColor) do
            local product = ProductUtil.getStampBookProduct("CoverColor", colorName)
            editPanel:AddWidgetFromProduct(TABS.CoverColor, product.Id, false, product, { VerifyOwnership = true }, function()
                currentStampData.StampBook.CoverColor = colorName
                updatedStampBookData.CoverColor = colorName
                readStampData()
            end)
        end

        -- Text Color
        editPanel:AddTab(TABS.TextColor, Images.Icons.Text)
        for colorName, _color in pairs(StampConstants.StampBook.TextColor) do
            local product = ProductUtil.getStampBookProduct("TextColor", colorName)
            editPanel:AddWidgetFromProduct(TABS.TextColor, product.Id, false, product, { VerifyOwnership = true }, function()
                currentStampData.StampBook.TextColor = colorName
                updatedStampBookData.TextColor = colorName
                readStampData()
            end)
        end

        -- Stamps
        editPanel:AddTab(TABS.Stamps, Images.Icons.Badge)

        -- Seal
        editPanel:AddTab(TABS.Seal, Images.Icons.Seal)
        for sealName, _sealInfo in pairs(StampConstants.StampBook.Seal) do
            local product = ProductUtil.getStampBookProduct("Seal", sealName)
            editPanel:AddWidgetFromProduct(TABS.Seal, product.Id, false, product, { VerifyOwnership = true }, function()
                currentStampData.StampBook.Seal = sealName
                updatedStampBookData.Seal = sealName
                readStampData()
            end)
        end

        -- Pattern
        editPanel:AddTab(TABS.Pattern, Images.Icons.Book)
        for patternName, _imageId in pairs(StampConstants.StampBook.CoverPattern) do
            local product = ProductUtil.getStampBookProduct("CoverPattern", patternName)
            editPanel:AddWidgetFromProduct(TABS.Pattern, product.Id, false, product, { VerifyOwnership = true }, function()
                currentStampData.StampBook.CoverPattern = patternName
                updatedStampBookData.CoverPattern = patternName
                readStampData()
            end)
        end

        ScreenUtil.outLeft(editPanel:GetContainer())
    end

    -- Register UIState
    do
        UIController.registerStateScreenCallbacks(UIConstants.States.StampBook, {
            Boot = StampBookScreen.boot,
            Shutdown = StampBookScreen.shutdown,
            Maximize = StampBookScreen.maximize,
            Minimize = StampBookScreen.minimize,
        })
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
    UIController.getStateMachine():Remove(UIConstants.States.StampInfo)

    -- Buttons
    do
        -- Igloo
        local iglooButton = createCoverButton(1)
        ButtonUtil.paintIgloo(iglooButton)
        iglooButton.Pressed:Connect(function()
            local houseZone = ZoneUtil.houseInteriorZone(currentPlayer)
            ZoneController.teleportToRoomRequest(houseZone)

            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
        end)

        -- Edit
        if currentPlayer == Players.LocalPlayer then
            local editButton = createCoverButton(2)
            ButtonUtil.paintEdit(editButton)
            editButton.Pressed:Connect(function()
                toggleEditMode()
            end)
        end
    end

    -- Picture
    local playerIcon = PlayerIcon.new(currentPlayer)
    playerIcon:Mount(cover.Picture.IconHolder, true)
    viewMaid:GiveTask(playerIcon)

    readStampData()
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
    local totalOwnedStampsOnPage = 0
    for _, stamp in pairs(chapterPage.Stamps) do
        if StampController.hasStamp(stamp.Id, nil, currentStampData.OwnedStamps) then
            totalOwnedStampsOnPage += 1
        end
    end

    inside.Chapter.StampCount.Text = ("%s/%d Stamps"):format(
        currentStampData.IsLoading and "?" or tostring(totalOwnedStampsOnPage),
        #chapterStructure.Layout[chapterPage.Key]
    )

    -- Pattern
    local pattern = currentStampData.StampBook.CoverPattern
    inside.Chapter.Pattern.Image = Images.StampBook.Patterns[pattern]

    -- Stamps
    for i, stamp in pairs(chapterPage.Stamps) do
        local holder = Instance.new("Frame")
        holder.LayoutOrder = i
        holder.Parent = inside.Chapter.Stamps
        chapterMaid:GiveTask(holder)

        local state: StampButton.State = {
            Progress = StampController.getProgress(stamp.Id, currentStampData.OwnedStamps),
        }
        local stampButton = StampButton.new(stamp, state)
        stampButton:Mount(holder, true)
        stampButton.Pressed:Connect(function()
            if isEditing then
                local didAdd = addCoverStamp(stamp)
                if didAdd then
                    Sound.play("Error")
                end
            else
                UIActions.showStampInfo(stamp.Id, state.Progress)
            end
        end)

        chapterMaid:GiveTask(stampButton)
    end
end

function StampBookScreen.boot(data: table)
    -- WARN: No player?!
    local player: Player = data.Player
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
    updatedStampBookData = {
        CoverStampIds = {},
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
        updatedStampBookData.CoverStampIds = TableUtil.toArray(currentStampData.StampBook.CoverStampIds)
        resolve(currentStampData)
    end)

    loadedStampData:andThen(function()
        if currentView == "Cover" then
            StampBookScreen.openCover()
        elseif currentView == "Inside" then
            StampBookScreen.openInside()
        end
    end)

    toggleEditMode(false)
end

function StampBookScreen.maximize()
    toggleEditMode(wasEditing)
    ScreenUtil.inDown(containerFrame)
    screenGui.Enabled = true
end

function StampBookScreen.minimize()
    toggleEditMode(false)
    ScreenUtil.outUp(containerFrame)
end

function StampBookScreen.shutdown()
    -- Inform Server of any changes
    Remotes.fireServer("StampBookData", updatedStampBookData)

    -- Close Routine
    toggleEditMode(false)
    currentChapter = nil
    wasEditing = false
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
