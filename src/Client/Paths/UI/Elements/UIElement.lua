local UIElement = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)

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
