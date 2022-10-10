--[[
    Simple Util class that can keep track of a scope.
    Room for expansion.

    Example:
        color() set's a part color to black, then 3 seconds later sets it to red. 
        If we call color() before those 3 seconds, we don't want the logic from the previous call setting it to red! So we could do:

        local colorScope = Scope.new()

        local function color()
            local scopeId = colorScope:NewScope()

            part.Color = COLOR_BLACK
            task.delay(3, function()
                if colorScope:Matches(scopeId) then
                    part.Color = COLOR_RED
                end
            end)
        end
]]
local Scope = {}

function Scope.new()
    local scope = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local id = 0

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    -- Returns Id
    function scope:NewScope()
        id += 1
        return id
    end

    function scope:GetId()
        return id
    end

    function scope:Matches(scopeId: number)
        return id == scopeId
    end

    return scope
end

return Scope
