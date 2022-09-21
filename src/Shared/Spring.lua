--[[
    Author: x_o
    Created: 03.09.2018
    Modified: 03.09.2018
    Spring module
--]]

-- TODO: Create a torsion spring

local Spring = {}
Spring.__index = Spring

function Spring.new(pos, mass, force, damping, speed)
    local self = setmetatable({}, Spring)

    self.Position = pos
    self.Velocity = Vector3.new()

    self.Mass = mass or 1
    self.Force = force or 50
    self.Damping = damping or 2
    self.Speed = speed or 1

    return self
end

function Spring:Shove(force)
    local x, y, z = force.X, force.Y, force.Z
    if x ~= x or x == math.huge or x == -math.huge then
        x = 0
    end
    if y ~= y or y == math.huge or y == -math.huge then
        y = 0
    end
    if z ~= z or z == math.huge or z == -math.huge then
        z = 0
    end

    self.Velocity = self.Velocity + Vector3.new(x, y, z)
end

function Spring:Update(target, dt)
    local scaledDeltaTime = math.min(dt * self.Speed, 0.1)

    local force = target - self.Position
    local acceleration = (force * self.Force) / self.Mass

    acceleration = acceleration - self.Velocity * self.Damping

    self.Velocity = self.Velocity + acceleration * scaledDeltaTime
    self.Position = self.Position + self.Velocity * scaledDeltaTime

    return self.Position
end

return Spring
