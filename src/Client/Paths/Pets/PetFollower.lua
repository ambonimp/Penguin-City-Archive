local PetFollower = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Pet = require(Paths.Shared.Pets.Pet)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local Maid = require(Paths.Packages.maid)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local CFrameUtil = require(Paths.Shared.Utils.CFrameUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

export type PetFollower = typeof(PetFollower.new())

type TickState = {
    IsMoving: boolean,
    IsJumping: boolean,
    Distance: number,
}
type MovementState = {
    Moving: {
        GoalPosition: Vector3,
    }?,
    Jumping: {
        StartPosition: Vector3,
        StartedAtTick: number,
    }?,
}

local VECTOR_DOWN = Vector3.new(0, -1, 0)
local RAYCAST_ORIGIN_OFFSET = Vector3.new(0, 5, 0)
local RAYCAST_LENGTH = 20
local EPSILON = 0.01

function PetFollower.new(model: Model)
    local petFollower = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    local character: Model

    local lastTickState: TickState | nil
    local movementState: MovementState = {}

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function getDistance()
        return (character:GetPivot().Position - model:GetPivot().Position).Magnitude
    end

    --[[
        Will try get a good side position by raycasting.

        If `useFootHeight`, will ignore raycast and return sideposition at the same height as the players feet.
    ]]
    local function getSidePosition(useFootHeight: boolean?)
        -- Get position offset from root part
        local humanoidRootPart: Part = character.HumanoidRootPart
        local sidePosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.RightVector.Unit * PetConstants.Following.SideDistance)

        if useFootHeight then
            return Vector3.new(
                sidePosition.X,
                humanoidRootPart.Position.Y - (humanoidRootPart.Size.Y / 2 + character.Humanoid.HipHeight),
                sidePosition.Z
            )
        end

        -- Raycast floor
        local raycastResult = RaycastUtil.raycast(sidePosition + RAYCAST_ORIGIN_OFFSET, VECTOR_DOWN, {
            FilterDescendantsInstances = { ZoneUtil.getZoneModel(ZoneController.getCurrentZone()) },
            FilterType = Enum.RaycastFilterType.Whitelist,
        }, RAYCAST_LENGTH)

        return raycastResult and raycastResult.Position or nil
    end

    -- `cframe` is the position of the pets feet
    local function setPetCFrame(cframe: CFrame)
        local centeredCFrame = cframe + Vector3.new(0, model.PrimaryPart.Size.Y / 2, 0)
        model:PivotTo(centeredCFrame)
    end

    -- Returns CFrame of the position of the pets feet
    local function getPetCFrame()
        local floorCFrame = model:GetPivot() - Vector3.new(0, model.PrimaryPart.Size.Y / 2, 0)
        return floorCFrame
    end

    local function doTick(dt: number)
        -- RETURN: No Character right now
        local currentCharacter = Players.LocalPlayer.Character
        if not currentCharacter then
            return
        end
        character = currentCharacter

        local humanoid: Humanoid = character.Humanoid
        local humanoidRootPart: Part = character.HumanoidRootPart

        -- Read State
        local thisTickState: TickState = {
            IsMoving = humanoid.MoveDirection.Magnitude > 0,
            IsJumping = humanoid:GetState() == Enum.HumanoidStateType.Freefall,
            Distance = getDistance(),
        }
        lastTickState = lastTickState or thisTickState -- First time init

        -- Make Decision
        do
            --* Moving
            if thisTickState.IsMoving then
                local doUpdatePosition = movementState.Moving or thisTickState.Distance > PetConstants.Following.MaxDistance
                if doUpdatePosition then
                    movementState.Moving = movementState.Moving or {}

                    movementState.Moving.GoalPosition = getSidePosition() or movementState.Moving.GoalPosition
                    if not movementState.Moving.GoalPosition then
                        movementState.Moving = nil
                    end
                end
            end

            --* Jumping
            if thisTickState.IsJumping then
                -- If we just jumped, and pet is not jumping
                if not lastTickState.IsJumping and not movementState.Jumping then
                    movementState.Jumping = movementState.Jumping or {}
                    movementState.Jumping.StartPosition = getPetCFrame().Position
                    movementState.Jumping.StartedAtTick = tick()
                end

                movementState.Moving = movementState.Moving or {}
                movementState.Moving.GoalPosition = getSidePosition(true)
            end
        end

        -- Move
        do
            -- Moving
            if movementState.Moving then
                setPetCFrame(CFrameUtil.setPosition(humanoidRootPart.CFrame, movementState.Moving.GoalPosition))

                -- Clear if close enough
                if (getPetCFrame().Position - movementState.Moving.GoalPosition).Magnitude < EPSILON then
                    movementState.Moving = nil
                end
            end

            -- Jumping
            if movementState.Jumping then
                -- Get Jump Height
                local progress = MathUtil.map(
                    tick(),
                    movementState.Jumping.StartedAtTick,
                    movementState.Jumping.StartedAtTick + PetConstants.Following.JumpDuration,
                    0,
                    1,
                    true
                )
                local heightAlpha = progress < 0.5 and progress or (1 - progress)
                local finalY = movementState.Jumping.StartPosition.Y + heightAlpha * PetConstants.Following.JumpHeight

                local currentCFrame = getPetCFrame()
                local newPosition = Vector3.new(currentCFrame.Position.X, finalY, currentCFrame.Position.Z)
                setPetCFrame(CFrameUtil.setPosition(currentCFrame, newPosition))

                -- Clear if jump completed
                if progress == 1 then
                    movementState.Jumping = nil
                end
            end
        end

        -- Update Cache
        lastTickState = thisTickState
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function petFollower:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    maid:GiveTask(RunService.RenderStepped:Connect(doTick))

    return petFollower
end

return PetFollower
