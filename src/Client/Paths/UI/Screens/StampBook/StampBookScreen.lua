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

local screenGui: ScreenGui = Ui.StampBook
local closeButton = KeyboardButton.new()
local sealButton: typeof(AnimatedButton.new(Instance.new("ImageButton")))
local cover: ImageLabel = screenGui.Container.Cover
local inside: Frame = screenGui.Container.Inside

local currentPlayer: Player?
local currentStampData = {
    OwnedStamps = {},
    StampBook = StampUtil.getStampBookDataDefaults(),
    IsLoading = true,
}
local loadedStampData = Promise.new(function() end) -- Intellisense hack
local currentView: "Cover" | "Inside"
local viewMaid = Maid.new()

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
                StampBookScreen.openCover()
            else
                UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.StampBook)
            end
        end)

        -- Seal
        sealButton = AnimatedButton.new(cover.Seal.Button)
        sealButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
        sealButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)
        sealButton.Pressed:Connect(StampBookScreen.openInside)

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

function StampBookScreen.openCover()
    -- Manage Internals
    currentView = "Cover"
    cover.Visible = true
    inside.Visible = false
    viewMaid:Cleanup()

    -- Buttons
    --!!temp
    for i = 1, 4 do
        local holder: Frame = cover.Buttons.template:Clone()
        holder.Name = tostring(i)
        holder.LayoutOrder = i
        holder.Visible = true
        holder.Parent = cover.Buttons

        local button = KeyboardButton.new()
        button:SetText(tostring(i))
        button:SetColor(Color3.new(math.random(), math.random(), math.random()))
        button:RoundOff()
        button:Mount(holder.Button)

        viewMaid:GiveTask(holder)
        viewMaid:GiveTask(button)
    end

    -- Picture
    --todo

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

    --todo
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
end

-- Setup UI
do
    -- Inside Tabs
    local tabs: Frame = inside.Tabs
    tabs.BackgroundTransparency = 1

    local tabsTemplate: ImageButton = tabs.template
    tabsTemplate.Visible = false

    for i, stampPage in pairs(StampConstants.Pages) do
        local pageTab = tabsTemplate:Clone()
        pageTab.Name = stampPage.DisplayName
        pageTab.LayoutOrder = i
        pageTab.Visible = true
        pageTab.Parent = tabs

        pageTab.Body.Icon.Image = stampPage.Icon

        local pageTabButton = Button.new(pageTab)
        pageTabButton.Pressed:Connect(function()
            print("todo", stampPage.StampType)
        end)
    end
end

return StampBookScreen
