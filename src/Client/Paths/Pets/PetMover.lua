local PetMover = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local AttachmentUtil = require(Paths.Shared.Utils.AttachmentUtil)
local Signal = require(Paths.Shared.Signal)

export type PetMover = typeof(PetMover.new())

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
type State = "Idle" | "Walking" | "Jumping"

local VECTOR_DOWN = Vector3.new(0, -1, 0)
local RAYCAST_ORIGIN_OFFSET = Vector3.new(0, 5, 0)
local RAYCAST_LENGTH = 20
local CLOSE_EPSILON = 0.1

local ALIGNER_PROPERTIES = {
    ALIGN_POSITION = {
        MaxForce = 100000,
        Responsiveness = 20,
    },
    ALIGN_ORIENTATION = {
        MaxTorque = 1000000,
        Responsiveness = 30,
    },
}

function PetMover.new(model: Model)
    local petMover = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false
    local character: Model
    local goalPart = Instance.new("Part")
    local goalAttachment = Instance.new("Attachment")
    local modelAttachment = Instance.new("Attachment")
    local alignPosition = Instance.new("AlignPosition")
    local alignOrientation = Instance.new("AlignOrientation")
    local lastTickState: TickState | nil
    local movementState: MovementState = {}

    local state: State = "Idle"

    maid:GiveTask(goalPart)

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    petMover.StateChanged = Signal.new() -- {state: "Idle" | "Walking" | "Jumping"}
    maid:GiveTask(petMover.StateChanged)

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function setState(newState: State)
        if newState ~= state then
            state = newState
            petMover.StateChanged:Fire(state)
        end
    end

    local function setup()
        modelAttachment.Name = "PetFollowerAttachment"
        modelAttachment.Parent = model.PrimaryPart
        modelAttachment.Position = Vector3.new(0, -model.PrimaryPart.Size.Y / 2, 0)

        goalPart.Size = Vector3.new(0.1, 0.1, 0.1)
        goalPart.Anchored = true
        goalPart.CanCollide = false
        goalPart.Transparency = 1
        goalPart.Name = "PetFollowerGoalPart"
        goalPart.Parent = game.Workspace

        goalAttachment.Parent = goalPart

        InstanceUtil.setProperties(alignPosition, ALIGNER_PROPERTIES.ALIGN_POSITION)
        alignPosition.Attachment0 = modelAttachment
        alignPosition.Attachment1 = goalAttachment
        alignPosition.Parent = model.PrimaryPart

        InstanceUtil.setProperties(alignOrientation, ALIGNER_PROPERTIES.ALIGN_ORIENTATION)
        alignOrientation.Attachment0 = modelAttachment
        alignOrientation.Attachment1 = goalAttachment
        alignOrientation.Parent = model.PrimaryPart

        model.PrimaryPart.CanCollide = false
    end

    local function getDistanceFromCharacter()
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
    local function setPetBottomCFrame(cframe: CFrame)
        goalPart:PivotTo(cframe)
    end

    -- Returns CFrame of the position of the pets feet
    local function getPetBottomCFrame()
        return AttachmentUtil.getWorldCFrame(modelAttachment)
    end

    local function doTick(_dt: number)
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
            Distance = getDistanceFromCharacter(),
        }
        lastTickState = lastTickState or thisTickState -- First time init

        -- Make Decision
        do
            --* Moving
            local isFarAway = thisTickState.Distance > PetConstants.Following.MaxDistance
            if thisTickState.IsMoving or isFarAway then
                local doUpdatePosition = movementState.Moving or isFarAway
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
                    movementState.Jumping.StartPosition = getPetBottomCFrame().Position
                    movementState.Jumping.StartedAtTick = tick()
                end

                movementState.Moving = movementState.Moving or {}
                movementState.Moving.GoalPosition = getSidePosition(true)
            end
        end

        -- Move
        do
            local finalState: State = "Idle"

            -- Moving
            if movementState.Moving then
                local newCFrame = CFrameUtil.setPosition(humanoidRootPart.CFrame, movementState.Moving.GoalPosition)
                setPetBottomCFrame(newCFrame)

                -- Clear if close enough
                local isCloseby = (getPetBottomCFrame().Position - movementState.Moving.GoalPosition).Magnitude < CLOSE_EPSILON
                if isCloseby then
                    movementState.Moving = nil
                else
                    finalState = "Walking"
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

                local currentCFrame = getPetBottomCFrame()
                local newPosition = Vector3.new(currentCFrame.Position.X, finalY, currentCFrame.Position.Z)
                setPetBottomCFrame(CFrameUtil.setPosition(currentCFrame, newPosition))

                -- Clear if jump completed
                if progress == 1 then
                    movementState.Jumping = nil
                else
                    finalState = "Jumping"
                end
            end

            setState(finalState)
        end

        -- Update Cache
        lastTickState = thisTickState
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function petMover:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    setup()

    maid:GiveTask(RunService.RenderStepped:Connect(doTick))

    return petMover
end

return PetMover
