local DefaultToolClientHandler = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Maid = require(Paths.Shared.Maid)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)

local ANIMATION_USE = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.UseGenericTool[1].Id })
local ANIMATION_HOLD = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.HoldGenericTool[1].Id })

--[[
    `modelSignal` is fired twice; once with our locally created model and once with the server created model.

    Returns a function that will be invoked when this tool gets unequipped
]]
function DefaultToolClientHandler.equipped(_tool: ToolUtil.Tool, _modelSignal: Signal.Signal, _equipMaid: Maid.Maid)
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

    local holdTrack = animator:LoadAnimation(ANIMATION_HOLD)
    holdTrack:Play()

    return function()
        holdTrack:Stop()
        holdTrack:Destroy()
    end
end

function DefaultToolClientHandler.unequipped(_tool: ToolUtil.Tool)
    --
end

function DefaultToolClientHandler.activatedLocally(_tool: ToolUtil.Tool, _modelGetter: () -> Model?)
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

    local useTrack = animator:LoadAnimation(ANIMATION_USE)
    useTrack:Play()
end

function DefaultToolClientHandler.activatedRemotely(_player: Player, _tool: ToolUtil.Tool, _model: Model?, _data: table?)
    --
end

return DefaultToolClientHandler
