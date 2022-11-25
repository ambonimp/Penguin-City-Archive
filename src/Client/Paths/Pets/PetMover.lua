--[[
    A class that moves a pet model around our local character
]]
local PetMover = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RunService = game:GetService("RunService")
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)
local Maid = require(Paths.Packages.maid)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local CFrameUtil = require(Paths.Shared.Utils.CFrameUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local AttachmentUtil = require(Paths.Shared.Utils.AttachmentUtil)
local Signal = require(Paths.Shared.Signal)

export type PetMover = typeof(PetMover.new())

type TickMemory = {
    IsMoving: boolean,
    IsJumping: boolean,
    Distance: number,
}
type MovementMemory = {
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
local PIVOT_TO_PLAYER_AT_DISTANCE = 200

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
    local character: Model = Players.LocalPlayer.Character
    local goalPart = Instance.new("Part")
    local goalAttachment = Instance.new("Attachment")
    local modelAttachment = Instance.new("Attachment")
    local alignPosition = Instance.new("AlignPosition")
    local alignOrientation = Instance.new("AlignOrientation")
    local lastTickMemory: TickMemory | nil
    local movementMemory: MovementMemory = {}
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

    local function updateState(newState: State)
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

        if character then
            goalPart:PivotTo(character:GetPivot())
        end

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

    local function getDistanceFromPetToCharacter()
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

        -- Use character's Y position
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
        local thisTickState: TickMemory = {
            IsMoving = humanoid.MoveDirection.Magnitude > 0,
            IsJumping = humanoid:GetState() == Enum.HumanoidStateType.Freefall,
            Distance = getDistanceFromPetToCharacter(),
        }

        -- Teleport
        local isVeryFarAway = thisTickState.Distance > PIVOT_TO_PLAYER_AT_DISTANCE
        if isVeryFarAway then
            local newCFrame = CFrameUtil.setPosition(character:GetPivot(), getSidePosition() or getSidePosition(true))

            model:PivotTo(newCFrame)
            goalPart:PivotTo(newCFrame)
        end

        -- Make Decision
        do
            --* Jumping
            if thisTickState.IsJumping then
                -- If we just jumped, and pet is not jumping
                if not (lastTickMemory and lastTickMemory.IsJumping) and not movementMemory.Jumping then
                    movementMemory.Jumping = movementMemory.Jumping or {}
                    movementMemory.Jumping.StartedAtTick = tick()
                end

                movementMemory.Moving = movementMemory.Moving or {}
                movementMemory.Moving.GoalPosition = getSidePosition()
            end

            --* Moving
            local isFarAway = thisTickState.Distance > PetConstants.Following.MaxDistance
            if thisTickState.IsMoving or isFarAway then
                local doUpdatePosition = movementMemory.Moving or isFarAway
                if doUpdatePosition then
                    movementMemory.Moving = movementMemory.Moving or {}

                    movementMemory.Moving.GoalPosition = getSidePosition() or movementMemory.Moving.GoalPosition
                end
            end

            if movementMemory.Moving and not movementMemory.Moving.GoalPosition then
                movementMemory.Moving = nil
            end
        end

        -- Move
        do
            local finalState: State = "Idle"

            -- Init Position
            if not lastTickMemory then
                setPetBottomCFrame(CFrameUtil.setPosition(humanoidRootPart.CFrame, getSidePosition() or getSidePosition(true)))
            end

            -- Moving
            if movementMemory.Moving then
                local newCFrame = CFrameUtil.setPosition(humanoidRootPart.CFrame, movementMemory.Moving.GoalPosition)
                setPetBottomCFrame(newCFrame)

                -- Clear if close enough
                local isCloseby = (getPetBottomCFrame().Position - movementMemory.Moving.GoalPosition).Magnitude < CLOSE_EPSILON
                if isCloseby then
                    movementMemory.Moving = nil
                else
                    finalState = "Walking"
                end
            end

            -- Jumping
            if movementMemory.Jumping then
                -- Get Jump Height
                local linearProgress = MathUtil.map(
                    tick(),
                    movementMemory.Jumping.StartedAtTick,
                    movementMemory.Jumping.StartedAtTick + PetConstants.Following.JumpDuration,
                    0,
                    1,
                    true
                )
                local heightAlpha = PetUtils.getHeightAlphaFromPetJumpProgress(linearProgress)

                local usePosition = movementMemory.Moving and movementMemory.Moving.GoalPosition
                    or getSidePosition()
                    or getSidePosition(true)
                local finalY = usePosition.Y + heightAlpha * PetConstants.Following.JumpHeight

                local currentPosition = movementMemory.Moving and movementMemory.Moving.GoalPosition or getPetBottomCFrame().Position
                local newPosition = Vector3.new(currentPosition.X, finalY, currentPosition.Z)
                setPetBottomCFrame(CFrameUtil.setPosition(humanoidRootPart.CFrame, newPosition))

                -- Clear if jump completed
                if linearProgress == 1 then
                    movementMemory.Jumping = nil
                else
                    finalState = "Jumping"
                end
            end

            updateState(finalState)
        end

        -- Update Cache
        lastTickMemory = thisTickState
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
