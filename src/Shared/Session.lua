--[[
    Represents a player's play session
]]
local Session = {}

function Session.new(player: Player)
    local session = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local startTick = tick()

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    -- Returns in seconds how long this player has been playing
    function session:GetPlayTime()
        return tick() - startTick
    end

    return session
end

return Session
