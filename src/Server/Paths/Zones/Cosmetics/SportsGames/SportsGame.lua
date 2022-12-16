local SportsGame = {}

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Limiter = require(Paths.Shared.Limiter)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local SportsGamesConstants = require(Paths.Shared.SportsGames.SportsGamesConstants)
local SportsGamesUtil = require(Paths.Shared.SportsGames.SportsGamesUtil)
local NetworkOwnerUtil = require(Paths.Shared.Utils.NetworkOwnerUtil)
local Sound = require(Paths.Shared.Sound)
local Particles = require(Paths.Shared.Particles)

local ZERO_VECTOR = Vector3.new(0, 0, 0)
local CONFETTI_DURATION = 1

--[[
    - `name`: name for the game
    - `cage`: A model of e.g., 6 parts that create a box that surrounds the play area. This keeps the `sportsEquipment` in bounds
    - `spawnpoint`: Part that the `sportsEquipment` spawns on
    - `goals`: Parts that cause a win when `sportsEquipment` enters it - and resets
    - `sportsEquipment`: E.g., football, hockey puck
]]
function SportsGame.new(name: string, cage: Model, spawnpoint: Part, goals: { Part }, sportsEquipmentType: string)
    local sportsGame = {}

    -- ERROR: Sports equipment needs a PrimaryPart
    local sportsEquipment = SportsGamesUtil.getSportsEquipment(sportsEquipmentType)
    if sportsEquipment:IsA("Model") and not sportsEquipment.PrimaryPart then
        error(("SportsEquipment %q needs PrimaryPart defined"):format(sportsEquipment:GetFullName()))
    end

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local scoreByGoal: { [Part]: number } = {}

    local currentSportsEquipment: Model | BasePart | nil

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function resetSportsEquipment()
        currentSportsEquipment:PivotTo(spawnpoint.CFrame + SportsGamesConstants.SpawnpointOffset)
        currentSportsEquipment.AssemblyLinearVelocity = ZERO_VECTOR
    end

    -- 1-time setup
    local function setup()
        -- Goals; score, touched, colliding
        for _, goalPart in pairs(goals) do
            scoreByGoal[goalPart] = 0

            goalPart.Touched:Connect(function(otherPart)
                -- RETURN: Not our sports equipment
                local isOurSportsEquipment = currentSportsEquipment
                    and (otherPart == currentSportsEquipment or otherPart:IsDescendantOf(currentSportsEquipment))
                if not isOurSportsEquipment then
                    return
                end

                -- Audio Feedback
                Sound.play("GoalScored", nil, goalPart)

                -- Visual Feedback
                local particles, adornee = Particles.playAtPosition("Confetti", otherPart:GetPivot().Position)
                task.delay(CONFETTI_DURATION, Particles.remove, particles, adornee)

                -- Reset
                resetSportsEquipment()
            end)

            goalPart.CanCollide = false
        end

        -- Collisions
        for _, cagePart in pairs(cage:GetDescendants()) do
            if cagePart:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(cagePart, CollisionsConstants.Groups.SportsArena)
            end
        end
        spawnpoint.CanCollide = false

        -- Hide Instances
        for _, instance: BasePart in pairs(ArrayUtil.merge(cage:GetDescendants(), { spawnpoint }, goals)) do
            if instance:IsA("BasePart") then
                instance.Transparency = 1
            end
        end

        -- Equipment
        do
            -- Setup
            currentSportsEquipment = sportsEquipment:Clone()

            currentSportsEquipment:SetAttribute(SportsGamesConstants.Attribute.SportsEquipmentType, sportsEquipmentType)
            CollectionService:AddTag(currentSportsEquipment, SportsGamesConstants.Tag.SportsEquipment)
            PhysicsService:SetPartCollisionGroup(currentSportsEquipment, CollisionsConstants.Groups.SportsEquipment)

            currentSportsEquipment.Name = ("%s_Sports_Equipment"):format(name)
            currentSportsEquipment.Anchored = false
            currentSportsEquipment.CanCollide = true
            currentSportsEquipment.Parent = cage

            -- Network Ownership; whoever touches it then owns it
            currentSportsEquipment.Touched:Connect(function(otherPart)
                -- RETURN: Not a player
                local player = CharacterUtil.getPlayerFromCharacterPart(otherPart)
                if not player then
                    return
                end

                -- RETURN: Touched by this player very recently
                local isFree = Limiter.debounce("SportsGame", player, SportsGamesConstants.PlayerTouchDebounceTime)
                if not isFree then
                    return
                end

                -- Set network ownership for every basepart
                local alreadyHadOwnership = false
                for _, instance: BasePart in pairs(ArrayUtil.merge(currentSportsEquipment:GetDescendants(), { currentSportsEquipment })) do
                    if instance:IsA("BasePart") then
                        alreadyHadOwnership = alreadyHadOwnership or instance:GetNetworkOwner() == player
                        NetworkOwnerUtil.setNetworkOwner(instance, player)
                    end
                end
            end)

            -- Spawn
            resetSportsEquipment()
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()
    resetSportsEquipment()

    return sportsGame
end

return SportsGame