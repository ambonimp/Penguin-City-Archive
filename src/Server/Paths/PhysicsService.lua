local Service = {}

local PhysicsService = game:GetService("PhysicsService")

type PhysicsGroups = { string }

local groups: PhysicsGroups = { "Default" }

local function createGroup(name: string)
    PhysicsService:CreateCollisionGroup(name)
    table.insert(groups, name)
end

local function setGroupCollideableBlacklist(group: string, blacklist: PhysicsGroups)
    for _, otherGroup in groups do
        if not table.find(blacklist, otherGroup) then
            PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
        else
            PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
        end
    end
end

local function setGroupCollideableWhitelist(group: string, whitelist: PhysicsGroups)
    for _, otherGroup in groups do
        if table.find(whitelist, otherGroup) then
            PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
        else
            PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
        end
    end
end

local function setCollision(group, collidableGroups: PhysicsGroups?, nonCollidableGroups: PhysicsGroups?)
    for _, otherGroup in (collidableGroups or {}) do
        PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
    end

    for _, otherGroup in (nonCollidableGroups or {}) do
        PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
    end
end

createGroup("HiddenCharacters")
setGroupCollideableWhitelist("HiddenCharacters", { "Default" })

return Service
