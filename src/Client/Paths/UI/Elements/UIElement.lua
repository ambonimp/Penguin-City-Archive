local UIElement = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)

function UIElement.new()
    local uiElement = {}

    -------------------------------------------------------------------------------
    -- Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    -------------------------------------------------------------------------------
    -- Methods
    -------------------------------------------------------------------------------

    function uiElement:GetMaid()
        return maid
    end

    function uiElement:Destroy()
        if isDestroyed then
            return
        end

        maid:Destroy()
        isDestroyed = true
    end

    return uiElement
end

return UIElement
