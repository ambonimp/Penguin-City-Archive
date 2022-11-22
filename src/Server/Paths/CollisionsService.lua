local CollisionsService = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)

type PhysicsGroups = { string }

local groupNames = CollisionsConstants.Groups
local groups: PhysicsGroups = { groupNames.Default }

local function createGroup(name: string)
    PhysicsService:CreateCollisionGroup(name)
    table.insert(groups, name)
end

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

-- Characters
createGroup(groupNames.Characters)
setGroupCollideableWhitelist(groupNames.Characters, { groupNames.Default, groupNames.Characters })

-- Hidden Characters
createGroup(groupNames.HiddenCharacters)
setGroupCollideableWhitelist(groupNames.HiddenCharacters, { groupNames.Default })

-- Ethereal Characters
createGroup(groupNames.EtherealCharacters)
setGroupCollideableWhitelist(groupNames.EtherealCharacters, { groupNames.Default })

-- Pet
createGroup(groupNames.Pet)
setGroupCollideableWhitelist(groupNames.Pet, { groupNames.Default })

return CollisionsService
