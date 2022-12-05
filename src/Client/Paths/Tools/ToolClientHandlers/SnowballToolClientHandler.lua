local SnowballToolClientHandler = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local Assume = require(Paths.Shared.Assume)
local Remotes = require(Paths.Shared.Remotes)
local Scope = require(Paths.Shared.Scope)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Maid = require(Paths.Packages.maid)
local SnowballToolUtil = require(Paths.Shared.Tools.Utils.SnowballToolUtil)
local MouseUtil = require(Paths.Client.Utils.MouseUtil)
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local Particles = require(Paths.Shared.Particles)

local ANIMATION_THROW_SNOWBALL = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.SnowballTool[1].Id })
local ANIMATION_THROW_EVENTS = {
    PickupSnowball = 9 / 30,
    ReleaseSnowball = 28 / 30,
}
local THROW_HEIGHT_PER_UNIT_DISTANCE = 0.2
local THROW_SPEED = 90
local MOUSE_RAYCAST_DISTANCE = 1000
local DESTROY_SNOWBALLS_AFTER = 15
local DESTROY_SNOWBALL_TWEEN_INFO = TweenInfo.new(1)
local ROTATE_CHARACTER_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
local MAX_SNOWBALL_MODELS = 40
local PLAY_LANDING_PARTICLE_FOR = 0.1

local isThrowingSnowball = false
local snowballModels: { Model } = {}

-------------------------------------------------------------------------------
-- Snowball Logic
-------------------------------------------------------------------------------

local function removeSnowball(snowballModel: Model)
    InstanceUtil.hide(snowballModel:GetDescendants(), DESTROY_SNOWBALL_TWEEN_INFO)
    task.delay(DESTROY_SNOWBALL_TWEEN_INFO.Time, function()
        snowballModel:Destroy()
    end)
end

--[[
    We throw the snowball along a bezier curve, where the intermediate point is the X/Z midpoint between the start and end position,
    and it's height is X units above the highest point of the start/end positions. X is calculated as a positive, additive function of the distance between
    the start and end position.
]]
local function throwSnowball(player: Player, goalPosition: Vector3, snowballModelGetter: () -> Model?, snowballTool: ToolUtil.Tool)
    -- Create function for animating the thrown snowball
    local function throwSnowballInArc(snowballModel: Model)
        -- Calculate the maths innit
        local startPosition = snowballModel:GetPivot().Position
        local directionVector = goalPosition - startPosition

        local length = directionVector.Magnitude
        local midpoint = VectorUtil.getXZComponents(startPosition + directionVector / 2)
            + Vector3.new(0, math.max(startPosition.Y, goalPosition.Y) + THROW_HEIGHT_PER_UNIT_DISTANCE * length, 0)

        -- We very badly estimate the length of the bezier curve to get the rough magnitude of its length to help us calculate speed / tween time
        -- Calculating the actual length of a bezier curve.. we don't need to be that accurate and I couldn't be bothered.
        local inaccurateBezierCurveLength = (midpoint - goalPosition).Magnitude + (midpoint - startPosition).Magnitude

        -- Setup Model
        local ourSnowballModel = ToolUtil.getModel(snowballTool):Clone()
        ourSnowballModel.Name = "Snowball"
        ourSnowballModel.Parent = game.Workspace
        ModelUtil.anchor(ourSnowballModel)

        -- Manage Snowball Models
        table.insert(snowballModels, ourSnowballModel)
        for i = #snowballModels, MAX_SNOWBALL_MODELS, -1 do
            local someSnowballModel = snowballModels[i]
            table.remove(snowballModels, i)
            removeSnowball(someSnowballModel)
        end

        -- Highlight local snowball
        local highlight: Highlight
        if player == Players.LocalPlayer then
            highlight = SnowballToolUtil.highlight(ourSnowballModel)
        end

        -- To infinity and beyond!
        TweenUtil.run(function(alpha)
            local alphaPosition = MathUtil.getQuadraticBezierPoint(alpha, startPosition, midpoint, goalPosition)
            ourSnowballModel:PivotTo(CFrame.new(alphaPosition))

            local hasLanded = alpha == 1
            if hasLanded then
                -- Remove Highlight
                if highlight then
                    highlight:Destroy()
                end

                -- Remove snowball model after a time
                task.delay(DESTROY_SNOWBALLS_AFTER, function()
                    local index = table.find(snowballModels, ourSnowballModel)
                    if index then
                        table.remove(snowballModels, index)
                        removeSnowball(ourSnowballModel)
                    end
                end)

                -- Play landing animation
                local particle = SnowballToolUtil.landingParticle(ourSnowballModel)
                task.delay(PLAY_LANDING_PARTICLE_FOR, function()
                    particle.Enabled = false
                    task.wait(particle.Lifetime.Max)
                    particle:Destroy()
                end)
            end
        end, TweenInfo.new(inaccurateBezierCurveLength / THROW_SPEED, Enum.EasingStyle.Linear))
    end

    -- TASK: Pickup Snowball
    task.delay(ANIMATION_THROW_EVENTS.PickupSnowball, function()
        -- Show snowball
        local model = snowballModelGetter()
        if model then
            SnowballToolUtil.showSnowball(model)
        end
    end)

    -- TASK: Release Snowball
    task.delay(ANIMATION_THROW_EVENTS.ReleaseSnowball, function()
        -- Hide snowball
        local model = snowballModelGetter()
        if model then
            SnowballToolUtil.hideSnowball(model)

            throwSnowballInArc(model)
        end
    end)
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

function SnowballToolClientHandler.equipped(_tool: ToolUtil.Tool, modelSignal: Signal.Signal, equipMaid: typeof(Maid.new()))
    -- Hide snowball by default
    equipMaid:GiveTask(modelSignal:Connect(function(snowballModel: Model, oldLocalSnowballModel: Model?)
        SnowballToolUtil.hideSnowball(snowballModel)

        -- We have just got the new server model - but what if we were already throwing our local version and it was visible?
        if oldLocalSnowballModel then
            SnowballToolUtil.matchSnowball(snowballModel, oldLocalSnowballModel)
        end
    end))
end

function SnowballToolClientHandler.activatedLocally(tool: ToolUtil.Tool, modelGetter: () -> Model?)
    -- RETURN: Already throwing a snowball!
    if isThrowingSnowball then
        return
    end

    -- RETURN: Bad raycast
    local mouseRaycastResult = MouseUtil.getMouseTarget(nil, nil, MOUSE_RAYCAST_DISTANCE)
    if not mouseRaycastResult then
        return
    end

    -- RETURN: No character!
    local character = Players.LocalPlayer.Character
    if not character then
        return
    end

    -- RETURN: No animator!
    local animator = character.Humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    -- Throw Snowball!
    do
        isThrowingSnowball = true

        -- Character: Anchor + Rotate
        local directionVector = mouseRaycastResult.Position - character:GetPivot().Position
        CharacterUtil.faceDirection(character, directionVector, ROTATE_CHARACTER_TWEEN_INFO)
        CharacterUtil.anchor(character)

        -- Play animation
        local throwTrack = animator:LoadAnimation(ANIMATION_THROW_SNOWBALL)
        throwTrack:Play()

        -- Throw
        throwSnowball(Players.LocalPlayer, mouseRaycastResult.Position, modelGetter, tool)

        -- Inform Server
        Remotes.fireServer("ToolActivated", tool.CategoryName, tool.ToolId, {
            Position = mouseRaycastResult.Position,
        })

        -- Finished
        task.delay(throwTrack.Length, function()
            -- Unanchor
            CharacterUtil.unanchor(character)

            isThrowingSnowball = false
        end)
    end
end

function SnowballToolClientHandler.activatedRemotely(player: Player, tool: ToolUtil.Tool, model: Model?, data: table?)
    -- RETURN: No model
    if not model then
        return
    end

    -- RETURN: Bad data
    local position = data and data.Position
    if not position then
        warn("Bad data passed", data)
        return
    end

    throwSnowball(player, position, function()
        return model
    end, tool)
end

return SnowballToolClientHandler
