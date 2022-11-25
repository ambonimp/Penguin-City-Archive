--[[
    Author: x_o
    Created: 03.09.2018
    Modified: 03.09.2018
    Spring module
--]]

local Spring = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vector3Util = require(ReplicatedStorage.Shared.Utils.Vector3Util)

local MIN_DELTA_TIME = 0.1

type NumVect = number | Vector3

function Spring.new(position: Vector3, speed: NumVect, mass: NumVect?, force: NumVect?, damping: NumVect?)
    local spring = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    mass = mass or 1
    force = force or 50
    damping = damping or 2
    speed = speed or 1

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function spring:Reset(newPosition)
        position = newPosition
        velocity = Vector3.new()
    end

    function spring:Set(newPosition: Vector3)
        position = newPosition
    end

    function spring:Get(): Vector3
        return position
    end

    function spring:Impuse(impule: Vector3)
        velocity = velocity + Vector3Util.ifNanThen0(impule)
    end

    function spring:Update(target: Vector3, dt: number)
        -- ERROR: Position isn't set
        if not position then
            error("Position isn't set")
        end

        local scaledSpeed = speed * dt
        local scaledDeltaTime = if typeof(speed) == "Vector3"
            then Vector3.new(
                math.min(scaledSpeed.Y, MIN_DELTA_TIME),
                math.min(scaledSpeed.Y, MIN_DELTA_TIME),
                math.min(scaledSpeed.Z, MIN_DELTA_TIME)
            )
            else math.min(scaledSpeed, MIN_DELTA_TIME)

        local impulse = target - position
        local acceleration = (impulse * force) / mass

        acceleration = acceleration - velocity * damping

        velocity = velocity + acceleration * scaledDeltaTime
        position = position + velocity * scaledDeltaTime

        return position
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    spring:Reset(position)

    return spring
end

return Spring
