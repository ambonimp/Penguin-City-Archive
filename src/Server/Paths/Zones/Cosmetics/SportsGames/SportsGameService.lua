local SportsGameService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local SportsGame = require(Paths.Server.Zones.Cosmetics.SportsGames.SportsGame)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local SportsGamesConstants = require(Paths.Shared.SportsGames.SportsGamesConstants)

local footballModel = ReplicatedStorage.Assets.Misc.Football

local function getArenaModelInstances(arenaModel: Model)
    -- Datastructure
    local instances = {} :: {
        Cage: Model,
        Spawnpoint: Part,
        Goals: { Part },
    }

    -- Cage
    local cage = InstanceUtil.findFirstChild(arenaModel, {
        ChildName = "Cage",
        ChildClassName = "Model",
    })
    if not cage then
        error("Missing Model `Cage`")
    end
    instances.Cage = cage

    -- Spawnpoint
    local spawnpoint = InstanceUtil.findFirstChild(arenaModel, {
        ChildName = "Spawnpoint",
        ChildClassName = "Part",
    })
    if not spawnpoint then
        error("Missing Part `Spawnpoint`")
    end
    instances.Spawnpoint = spawnpoint

    -- Goals
    local goals = InstanceUtil.findChildren(arenaModel, {
        ChildName = "Goal",
        ChildClassName = "Part",
    })
    if #goals == 0 then
        error("No Parts `Goal`; needs atleast one")
    end
    instances.Goals = goals

    --

    -- Verify some needed assumptions
    for _, instance: BasePart in pairs(ArrayUtil.merge(cage:GetDescendants(), { spawnpoint }, goals)) do
        if instance:IsA("BasePart") then
            if not instance.Anchored then
                warn(("%s is not anchored!"):format(instance:GetFullName()))
            end
        end
    end

    return instances
end

function SportsGameService.zoneSetup()
    -- School Football Arena
    do
        local schoolFootballArenaModel = game.Workspace.Rooms.School.FootballPitch
        local success, result = pcall(getArenaModelInstances, schoolFootballArenaModel)
        if success then
            SportsGame.new(
                "SchoolFootball",
                result.Cage,
                result.Spawnpoint,
                result.Goals,
                SportsGamesConstants.SportsEquipmentType.Football
            )
        else
            error(("Error with School FootballPitch: %s"):format(result))
        end
    end

    -- Hockey Stadium
    do
        local hockeyArenaModel = game.Workspace.Rooms.HockeyStadium.HockeyArena
        local success, result = pcall(getArenaModelInstances, hockeyArenaModel)
        if success then
            SportsGame.new(
                "HockeyStadiumArena",
                result.Cage,
                result.Spawnpoint,
                result.Goals,
                SportsGamesConstants.SportsEquipmentType.HockeyPuck
            )
        else
            error(("Error with HockeyStadium Arena: %s"):format(result))
        end
    end
end

return SportsGameService
