--[[
    A `Hitbox` object with added functionality for detecting players being in the hitbox. Uses ONLY HumanoidRootPart (performance reasons)
    
    Can only be defined by adding parts, as we use Touched+TouchEnded events and GetPartsInPart
]]
local PlayersHitbox = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Hitbox = require(ReplicatedStorage.Shared.Hitbox)
local CharacterUtil = require(ReplicatedStorage.Shared.Utils.CharacterUtil)
local Signal = require(ReplicatedStorage.Shared.Signal)

local VALIDATE_EVERY = 0.5

function PlayersHitbox.new()
    local playersHitbox = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local hitbox = Hitbox.new()
    local maid = hitbox:GetMaid()
    local isDestroyed = false
    local validator: RBXScriptConnection?

    local cachedPlayers: { [Player]: boolean } = {}

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    playersHitbox.PlayerEntered = Signal.new() -- {player: Player}
    playersHitbox.PlayerLeft = Signal.new() -- {player: Player}

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function stopValidator()
        -- RETURN: Not running
        if not validator then
            return
        end

        validator:Disconnect()
        validator = nil
    end

    local function runValidator()
        -- RETURN: Already running
        if validator then
            return
        end

        local lastValidationAtTick = tick()
        validator = RunService.Heartbeat:Connect(function()
            -- RETURN: Not enough time elapsed
            if tick() - lastValidationAtTick < VALIDATE_EVERY then
                return
            end
            lastValidationAtTick = tick()

            -- Validate cachedPlayers
            for player, _ in pairs(cachedPlayers) do
                if (not player:IsDescendantOf(Players)) or not playersHitbox:IsPlayerInside(player) then
                    playersHitbox.PlayerLeft:Fire(player)
                    cachedPlayers[player] = nil
                end
            end

            -- Stop validation if needs be
            if TableUtil.isEmpty(cachedPlayers) then
                stopValidator()
            end
        end)
    end

    local function partTouched(otherPart: BasePart)
        -- RETURN: No player
        local player = CharacterUtil.getPlayerFromCharacterPart(otherPart, true)
        if not player then
            return
        end

        if not cachedPlayers[player] then
            cachedPlayers[player] = true
            playersHitbox.PlayerEntered:Fire(player)

            runValidator()
        end
    end

    local function partTouchEnded(otherPart: BasePart)
        -- RETURN: No player
        local player = CharacterUtil.getPlayerFromCharacterPart(otherPart, true)
        if not player then
            return
        end

        if not playersHitbox:IsPlayerInside(player) then
            if cachedPlayers[player] then
                cachedPlayers[player] = nil
                playersHitbox.PlayerLeft:Fire(player)

                if TableUtil.isEmpty(cachedPlayers) then
                    stopValidator()
                end
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function playersHitbox:AddPart(part: BasePart)
        hitbox:AddPart(part)
        part.Touched:Connect(partTouched)
        part.TouchEnded:Connect(partTouchEnded)

        return self
    end

    function playersHitbox:AddParts(addParts: { BasePart })
        for _, part in pairs(addParts) do
            self:AddPart(part)
        end

        return self
    end

    function playersHitbox:IsPlayerInside(player: Player)
        -- FALSE: No root part
        local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return false
        end

        return hitbox:IsPartInside(humanoidRootPart)
    end

    -- Returns internal cache
    function playersHitbox:GetPlayersInside()
        return TableUtil.deepClone(cachedPlayers)
    end

    --[[
        Fires .PlayerLeft for all internally cached players too
    ]]
    function playersHitbox:Destroy(doDestroyParts: boolean?)
        if isDestroyed then
            return
        end
        isDestroyed = true

        for player, _ in pairs(cachedPlayers) do
            playersHitbox.PlayerLeft:Fire(player)
        end
        cachedPlayers = {}

        hitbox:Destroy(doDestroyParts)
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Cleanup
    maid:GiveTask(stopValidator)
    maid:GiveTask(playersHitbox.PlayerEntered)
    maid:GiveTask(playersHitbox.PlayerLeft)

    return playersHitbox
end

return PlayersHitbox
