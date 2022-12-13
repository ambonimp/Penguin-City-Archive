local SportsGame = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local CollisionsConstants = require(Paths.Shared.Constants.CollisionsConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

local SPAWNPOINT_SPAWN_OFFSET = Vector3.new(0, 5, 0)

--[[
    - `name`: name for the game
    - `cage`: A model of e.g., 6 parts that create a box that surrounds the play area. This keeps the `sportsEquipment` in bounds
    - `spawnpoint`: Part that the `sportsEquipment` spawns on
    - `goals`: Parts that cause a win when `sportsEquipment` enters it - and resets
    - `sportsEquipment`: E.g., football, hockey puck
]]
function SportsGame.new(name: string, cage: Model, spawnpoint: Part, goals: { Part }, sportsEquipment: Model | BasePart)
    local sportsGame = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local scoreByGoal: { [Part]: number } = {}

    local currentSportsEquipment: Model | BasePart | nil

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function spawnSportsEquipment()
        -- Destroy current
        if currentSportsEquipment then
            currentSportsEquipment:Destroy()
        end

        -- Setup Equipment; pivot, properties etc
        currentSportsEquipment = sportsEquipment:Clone()
        PhysicsService:SetPartCollisionGroup(currentSportsEquipment, CollisionsConstants.Groups.SportsEquipment)
        currentSportsEquipment.Name = ("%s_Sports_Equipment"):format(name)
        currentSportsEquipment:PivotTo(spawnpoint.CFrame + SPAWNPOINT_SPAWN_OFFSET)
        currentSportsEquipment.Anchored = false
        currentSportsEquipment.CanCollide = true
        currentSportsEquipment.Parent = game.Workspace

        -- Network Ownership; whoever touches it then owns it
        currentSportsEquipment.Touched:Connect(function(otherPart)
            -- RETURN: Not a player
            local player = CharacterUtil.getPlayerFromCharacterPart(otherPart)
            if not player then
                return
            end

            -- Set network ownership for every basepart
            for _, instance: BasePart in pairs(ArrayUtil.merge(currentSportsEquipment:GetDescendants(), { currentSportsEquipment })) do
                if instance:IsA("BasePart") then
                    instance:SetNetworkOwner(player)
                end
            end
        end)
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

                print(goalPart:GetFullName(), "touched", otherPart:GetFullName())
                spawnSportsEquipment()
            end)

            goalPart.CanCollide = false
        end

        -- Collisions
        for _, cagePart in pairs(cage:GetDescendants()) do
            if cagePart:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(cagePart, CollisionsConstants.Groups.SportsPitch)
            end
        end
        spawnpoint.CanCollide = false

        -- Hide Instances
        for _, instance: BasePart in pairs(ArrayUtil.merge(cage:GetDescendants(), { spawnpoint }, goals)) do
            if instance:IsA("BasePart") then
                instance.Transparency = 1
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()
    spawnSportsEquipment()

    return sportsGame
end

return SportsGame
