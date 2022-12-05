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

local ANIMATION_THROW_SNOWBALL = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.SnowballTool[1].Id })
local ANIMATION_EVENT_PICKUP_SNOWBALL = "PickupSnowball"
local ANIMATION_EVENT_RELEASE_SNOWBALL = "ReleaseSnowball"

local isThrowingSnowball = false

-------------------------------------------------------------------------------
-- Snowball Logic
-------------------------------------------------------------------------------

local function throwSnowball(position: Vector3, snowballModel: Model)
    --!! temp
    DebugUtil.flashPoint(position, snowballModel.PrimaryPart.Color)
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

function SnowballToolClientHandler.unequipped(tool: ToolUtil.Tool)
    print("unequipped", tool)
end

function SnowballToolClientHandler.activatedLocally(tool: ToolUtil.Tool, modelGetter: () -> Model?)
    -- RETURN: Already throwing a snowball!
    if isThrowingSnowball then
        return
    end

    -- RETURN: Bad raycast
    local mouseRaycastResult = MouseUtil.getMouseTarget()
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

        -- Anchor
        CharacterUtil.anchor(character)

        -- Play animation
        local throwTrack = animator:LoadAnimation(ANIMATION_THROW_SNOWBALL)
        throwTrack:Play()

        -- Pickup Snowball
        throwTrack:GetMarkerReachedSignal(ANIMATION_EVENT_PICKUP_SNOWBALL):Connect(function()
            -- Show snowball
            local model = modelGetter()
            if model then
                SnowballToolUtil.showSnowball(model)
            end
        end)

        -- Release Snowball
        throwTrack:GetMarkerReachedSignal(ANIMATION_EVENT_RELEASE_SNOWBALL):Connect(function()
            local model = modelGetter()
            if model then
                -- Throw
                do
                    throwSnowball(mouseRaycastResult.Position, model)

                    -- Inform Server
                    Remotes.fireServer("ToolActivated", tool.CategoryName, tool.ToolName, {
                        Position = mouseRaycastResult.Position,
                    })
                end

                -- Hide snowball
                SnowballToolUtil.hideSnowball(model)
            end
        end)

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

    print("THROW REMOTE")
    throwSnowball(position, model)
end

return SnowballToolClientHandler
