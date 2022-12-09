local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")
local RadialMenu = require(script.Parent.RadialMenu)
local Button = require(script.Parent.Button)

local FONT = Enum.Font.Highway
local FONT_SIZE = 30

local camera = Workspace.CurrentCamera

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 300, 0, 300)
    frame.Parent = target

    local radialMenu = RadialMenu.new()

    local strings = {}
    local longestString = ""
    for i = 1, 4 do
        local rng = math.random(1, 5)
        local str = ("%s (%d)"):format(string.rep(rng :: string, rng), i)
        table.insert(strings, str)

        if #str > #longestString then
            longestString = str
        end
    end

    local textSize = TextService:GetTextSize(longestString, FONT_SIZE, FONT, camera.ViewportSize)
    local textDim = UDim2.fromOffset(textSize.X, textSize.Y)
    local buttonDim = textDim + UDim2.fromOffset(20, 0)

    for _, str in pairs(strings) do
        local imageButton: ImageButton = Instance.new("ImageButton")
        imageButton.BackgroundColor3 = Color3.fromRGB(98, 195, 255)
        imageButton.BackgroundTransparency = 0.2
        imageButton.Size = buttonDim

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(1, 1, 1)
        stroke.Thickness = 4
        stroke.Parent = imageButton

        local roundedCorners = Instance.new("UICorner")
        roundedCorners.CornerRadius = UDim.new(0.5, 0)
        roundedCorners.Parent = imageButton

        local textLabel = Instance.new("TextLabel")
        textLabel.BackgroundTransparency = 1
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        textLabel.Position = UDim2.fromScale(0.5, 0.5)
        textLabel.Size = textDim
        textLabel.Font = FONT
        textLabel.TextSize = FONT_SIZE
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Text = str
        textLabel.TextWrapped = false
        textLabel.TextTruncate = Enum.TextTruncate.None
        textLabel.Parent = imageButton

        radialMenu:AddButton(Button.new(imageButton)).Pressed:Connect(function()
            radialMenu:Close()
        end)
    end

    radialMenu:Mount(frame)
    radialMenu:Open()

    return function()
        frame:Destroy()
        radialMenu:Destroy()
    end
end
