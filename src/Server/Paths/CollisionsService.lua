local CollisionsService = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)

type PhysicsGroups = { string }

local groups = CollisionsConstants.Groups
local function _setGroupCollideableBlacklist(group: string, blacklist: PhysicsGroups)
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

local function _setCollision(group, collidableGroups: PhysicsGroups?, nonCollidableGroups: PhysicsGroups?)
    for _, otherGroup in (collidableGroups or {}) do
        PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
    end

    for _, otherGroup in (nonCollidableGroups or {}) do
        PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
    end
end

function CollisionsService.getCollisionGroupId(groupName: string)
    return PhysicsService:GetCollisionGroupId(groupName)
end

for _, group in pairs(CollisionsConstants.Groups) do
    if group ~= CollisionsConstants.Groups.Default then
        PhysicsService:CreateCollisionGroup(group)
    end
end

-- Characters
setGroupCollideableWhitelist(groups.Characters, { groups.Default, groups.Characters })

-- Hidden Characters
setGroupCollideableWhitelist(groups.HiddenCharacters, { groups.Default })

-- Ethereal Characters
setGroupCollideableWhitelist(groups.EtherealCharacters, { groups.Default })

-- Sled race
setGroupCollideableWhitelist(groups.SledRaceCollectables, { groups.Default })

-- Pet
setGroupCollideableWhitelist(groups.Pet, { groups.Default })

return CollisionsService
