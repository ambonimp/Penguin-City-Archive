--[[
    Author: x_o
    Created: 03.09.2018
    Modified: 03.09.2018
    Spring module
--]]

local Spring = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VectorUtil = require(ReplicatedStorage.Shared.Utils.VectorUtil)

function Spring.new(position: Vector3, mass: Vector3?, force: Vector3?, damping: Vector3?, speed: Vector3)
    local spring = setmetatable({}, Spring)

    local velocity = Vector3.new()

    mass = mass or 1
    force = force or 50
    damping = damping or 2
    speed = speed or 1

    function spring:Set(newPosition: Vector3)
        position = newPosition
    end

    function spring:Get(): Vector3
        return position
    end

    function spring:Impuse(impule: Vector3)
        velocity = velocity + VectorUtil.ifNanThen0(impule)
    end

    function spring:Update(target: Vector3, dt: number)
        local scaledDeltaTime = math.min(dt * self.Speed, 0.1)

        local impulse = target - position
        local acceleration = (impulse * force) / mass

        acceleration = acceleration - velocity * damping

        velocity = velocity + acceleration * scaledDeltaTime
        position = position + velocity * scaledDeltaTime

        return position
    end

    return spring
end

return Spring
