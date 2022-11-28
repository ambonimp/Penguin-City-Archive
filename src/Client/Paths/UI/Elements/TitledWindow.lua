local TitledWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIElement = require(Paths.Client.UI.Elements.UIElement)

--[[
    data:
    - AddCallback: If passed, will create an "Add" button that will invoke AddCallback
]]
function TitledWindow.new(icon: string, title: string, subtext: string?)
    local titledWindow = UIElement.new()
    local maid = titledWindow:GetMaid()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local container = Instance.new("Frame")
    container.Name = "container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)
    maid:GiveTask(container)

    local top = Instance.new("Frame")
    top.Name = "top"
    top.BackgroundTransparency = 1
    top.Size = UDim2.fromScale(1, 0.2)

    local topIcon = Instance.new("ImageLabel")
    topIcon.Name = "topIcon"
    topIcon.Image = "rbxassetid://11505043486"
    topIcon.AnchorPoint = Vector2.new(0, 0.5)
    topIcon.BackgroundTransparency = 1
    topIcon.Position = UDim2.fromScale(0.05, 0.5)
    topIcon.Size = UDim2.fromOffset(130, 130)
    topIcon.ScaleType = Enum.ScaleType.Fit
    topIcon.Parent = top

    local topTitle = Instance.new("TextLabel")
    topTitle.Name = "topTitle"
    topTitle.Font = UIConstants.Font
    topTitle.Text = "Hoverboards"
    topTitle.TextColor3 = Color3.fromRGB(38, 71, 118)
    topTitle.TextSize = 80
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.AnchorPoint = Vector2.new(0, 0.5)
    topTitle.BackgroundTransparency = 1
    topTitle.Position = UDim2.new(0.05, 140, 0.5, 0)
    topTitle.Size = UDim2.fromScale(0.4, 1)
    topTitle.Parent = top

    local topSubtext = Instance.new("TextLabel")
    topSubtext.Name = "topSubtext"
    topSubtext.Font = UIConstants.Font
    topSubtext.Text = subtext or ""
    topSubtext.TextColor3 = Color3.fromRGB(38, 71, 118)
    topSubtext.TextSize = 40
    topSubtext.TextXAlignment = Enum.TextXAlignment.Right
    topSubtext.TextYAlignment = Enum.TextYAlignment.Bottom
    topSubtext.AnchorPoint = Vector2.new(1, 1)
    topSubtext.BackgroundTransparency = 1
    topSubtext.Position = UDim2.fromScale(0.95, 0.95)
    topSubtext.Size = UDim2.fromScale(0.4, 0.2)
    topSubtext.Parent = top

    top.Parent = container

    local divider = Instance.new("Frame")
    divider.Name = "divider"
    divider.AnchorPoint = Vector2.new(0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(219, 236, 255)
    divider.Position = UDim2.fromScale(0.5, 0.2)
    divider.Size = UDim2.fromScale(0.9, 0.01)

    local dividerCorner = Instance.new("UICorner")
    dividerCorner.Name = "dividerCorner"
    dividerCorner.CornerRadius = UDim.new(0, 100)
    dividerCorner.Parent = divider

    divider.Parent = container

    local windowHolder = Instance.new("Frame")
    windowHolder.Name = "windowHolder"
    windowHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    windowHolder.BackgroundTransparency = 1
    windowHolder.Position = UDim2.fromScale(0, 0.22)
    windowHolder.Size = UDim2.fromScale(1, 0.77)
    windowHolder.Parent = container
    --#endregion

    topIcon.Image = icon
    topTitle.Text = title

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    -- Setters

    function titledWindow:SetIcon(imageId: string)
        topIcon.Image = imageId
    end

    function titledWindow:SetTitle(text: string)
        topTitle.Text = text
    end

    function titledWindow:SetSubText(subText: string)
        topSubtext.Text = subText
    end

    -- Getters / Mount

    function titledWindow:GetContainer()
        return container
    end

    function titledWindow:GetWindowHolder()
        return windowHolder
    end

    function titledWindow:Mount(parent: GuiObject)
        container.Parent = parent
    end

    return titledWindow
end

return TitledWindow
