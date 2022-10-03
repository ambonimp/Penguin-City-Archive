local ImageViewer = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Client.Images.Images)
local UIConstants = require(Paths.Client.UI.UIConstants)

local IMAGES_RESOLUTION = Vector2.new(10, 5) -- How many images to display on X/Y axis

local screenGui: ScreenGui?

local function createImageDisplay(label: string, imageId: string)
    local imageDisplay = Instance.new("Frame")
    imageDisplay.Name = "imageDisplay"
    imageDisplay.BackgroundTransparency = 1

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 4)
    uIPadding.PaddingLeft = UDim.new(0, 4)
    uIPadding.PaddingRight = UDim.new(0, 4)
    uIPadding.PaddingTop = UDim.new(0, 4)
    uIPadding.Parent = imageDisplay

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "textLabel"
    textLabel.Font = UIConstants.Font
    textLabel.Text = label
    textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.TextWrapped = true
    textLabel.AnchorPoint = Vector2.new(0.5, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.fromScale(0.5, 1)
    textLabel.Size = UDim2.fromScale(1, 0.2)
    textLabel.Parent = imageDisplay

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Name = "uiStroke"
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Parent = textLabel

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "imageLabel"
    imageLabel.Image = imageId
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.AnchorPoint = Vector2.new(0.5, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Position = UDim2.fromScale(0.5, 0)
    imageLabel.Size = UDim2.fromScale(0.8, 0.8)
    imageLabel.Parent = imageDisplay

    return imageDisplay
end

local function createSectionDisplay(label: string)
    local display = createImageDisplay(label, "")
    local textLabel: TextLabel = display.textLabel:Clone()
    local imageLabel: ImageLabel = display.imageLabel

    textLabel.Size = imageLabel.Size
    textLabel.Position = imageLabel.Position
    textLabel.AnchorPoint = imageLabel.AnchorPoint
    textLabel.Parent = imageLabel.Parent

    display.textLabel.Text = ">>>>>>>>"
    imageLabel:Destroy()

    return display
end

function ImageViewer.viewImages()
    ImageViewer.clearImages()

    -- Create screenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ImageViewer"
    screenGui.Parent = Players.LocalPlayer.PlayerGui

    -- ScrollingFrame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.fromScale(1, 1)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = screenGui

    -- UIGridLayout
    local uIGridLayout = Instance.new("UIGridLayout")
    uIGridLayout.Name = "uIGridLayout"
    uIGridLayout.CellPadding = UDim2.new()
    uIGridLayout.CellSize = UDim2.fromScale(1 / IMAGES_RESOLUTION.X, 1 / IMAGES_RESOLUTION.Y)
    uIGridLayout.Parent = scrollingFrame

    local function iterateImageIdTable(tbl: table)
        for key, value in pairs(tbl) do
            if typeof(value) == "table" then
                iterateImageIdTable(value)
            elseif typeof(value) == "string" then
                createImageDisplay(tostring(key), value).Parent = scrollingFrame
            end
        end
    end

    for sectionName, imageTable in pairs(Images) do
        createSectionDisplay(sectionName).Parent = scrollingFrame
        iterateImageIdTable(imageTable)
    end
end

function ImageViewer.clearImages()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

return ImageViewer
