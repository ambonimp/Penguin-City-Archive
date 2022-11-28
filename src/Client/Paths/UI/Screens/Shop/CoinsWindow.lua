local CoinsWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Maid = require(Paths.Packages.maid)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local TitledWindow = require(Paths.Client.UI.Elements.TitledWindow)
local Images = require(Paths.Shared.Images.Images)

function CoinsWindow.new()
    local coinsWindow = TitledWindow.new(Images.Coins.Coin, "Coins", "Buy Coins Here!")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    --todo

    return coinsWindow
end

return CoinsWindow
