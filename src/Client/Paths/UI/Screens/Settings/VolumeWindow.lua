local VolumeWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local TitledWindow = require(Paths.Client.UI.Elements.TitledWindow)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ProductController = require(Paths.Client.ProductController)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

function VolumeWindow.new()
    local volumeWindow = TitledWindow.new(Images.ButtonIcons.Settings, "Settings", "Customise your experience")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local container = Instance.new("Frame")
    container.Name = "container"
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)
    --#endregion

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    container.Parent = volumeWindow:GetWindowHolder()

    return volumeWindow
end

return VolumeWindow
