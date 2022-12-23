local Snackbar = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local HEIGHT = 0.15

local BUMP_LENGTH = 0.5
local LIFETIME = 5
local PADDING = 0.025
local BINDING_KEY = "OPEN"

local templates = Paths.Templates.Snackbars
local container = Paths.UI.Snackbars.Container

local function move(item: TextLabel, position: UDim2)
    item:TweenPosition(position, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, BUMP_LENGTH, true)
end

local function write(template: TextLabel, message: string)
    -- Add new
    local snackbar = container:FindFirstChild(message)
    if snackbar then
        snackbar = nil
        for _, otherSnackbar in pairs(container:GetChildren()) do
            if otherSnackbar.Name == message and otherSnackbar.LayoutOrder == 0 then
                snackbar = otherSnackbar
                break
            end
        end
    end

    if not snackbar then
        -- Bump Others
        for _, otherSnackbar in ipairs(container:GetChildren()) do
            local order = otherSnackbar.LayoutOrder + 1

            move(otherSnackbar, UDim2.fromScale(0.5, 1 - order * (HEIGHT + PADDING)))
            otherSnackbar.LayoutOrder = order
        end

        snackbar = template:Clone()
        snackbar.Name = message
        snackbar.Text = message
        snackbar.LayoutOrder = 0
        snackbar.Visible = true
        snackbar.Parent = container
    end

    snackbar.Size = UDim2.fromScale(0, snackbar.Size.Y.Scale)
    snackbar.TextColor3 = template.TextColor3
    snackbar.TextTransparency = template.TextTransparency
    snackbar.BackgroundTransparency = template.BackgroundTransparency
    snackbar.Position = UDim2.fromScale(0.5, 1)

    TweenUtil.bind(
        snackbar,
        BINDING_KEY,
        TweenService:Create(
            snackbar,
            TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { Size = UDim2.fromScale(1, HEIGHT) }
        ),
        function(openingPlaybackState)
            if openingPlaybackState == Enum.PlaybackState.Completed then
                TweenUtil.bind(
                    snackbar,
                    BINDING_KEY,
                    TweenService:Create(
                        snackbar,
                        TweenInfo.new(LIFETIME * 0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, LIFETIME * 0.75),
                        { TextTransparency = 1, TextStrokeTransparency = 1 }
                    ),
                    function(closingPlaybackState)
                        if closingPlaybackState == Enum.PlaybackState.Completed then
                            snackbar:Destroy()
                        end
                    end
                )
            end
        end
    )
end

function Snackbar.error(message)
    write(templates.Error, message)
end

function Snackbar.info(message)
    write(templates.Info, message)
end

return Snackbar
