local SledRaceCollectables = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local Images = require(Paths.Shared.Images.Images)
local CollisionConstants = require(Paths.Shared.Constants.CollisionsConstants)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local CameraController = require(Paths.Client.Minigames.SledRace.SledRaceCamera)
local DrivingController = require(Paths.Client.Minigames.SledRace.SledRaceDriving)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local SledRaceScreen = require(Paths.Client.UI.Screens.Minigames.SledRaceScreen)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local Sound = require(Paths.Shared.Sound)

local MAX_OBSTACLE_MASS = 2800
local FLING_FORCE = { Min = 125, Max = 200 }
local FLING_TWEEN_INFO = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()

local player = Players.LocalPlayer

local assets = ReplicatedStorage.Assets.Minigames.SledRace
local particles = assets.Particles

local coinsCollected: number

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
function weighted(weight, value) -- Literally just for readibility
    return weight * value
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SledRaceCollectables.setup()
    local map = MinigameController.getMap()
    local collectables = map:WaitForChild("Collectables")

    local character: Model = player.Character
    local characterCFrame, characterSize = character:GetBoundingBox()

    local sled: Model = SledRaceUtil.getSled(player)
    local physicsPart: BasePart = sled:WaitForChild("Physics")

    local hitDebounces: { [Model]: boolean } = {}
    local hitbox: Part = Instance.new("Part")
    hitbox.Transparency = 1
    hitbox.Size = characterSize
    hitbox.CFrame = characterCFrame
    hitbox.Massless = true
    hitbox.CanCollide = false
    hitbox.Parent = character
    BasePartUtil.weld(hitbox, physicsPart)

    coinsCollected = 0

    local colliding: RBXScriptConnection = hitbox.Touched:Connect(function(hit: BasePart)
        -- RETURN: Hit is not a part of a collideable
        if hit.CollisionGroup ~= CollisionConstants.Groups.SledRaceCollectables then
            return
        end

        local collectable = hit
        repeat
            collectable = collectable.Parent
        until not collectable or collectable.Parent == collectables

        -- RETURN: Collectable no longer exists
        if not collectable or hitDebounces[collectable] then
            return
        end

        hitDebounces[collectable] = true

        local collectableCFrame: CFrame, collectableSize: Vector3 = collectable:GetBoundingBox()
        local collisionPoint = BasePartUtil.closestPoint(hitbox, {
            CFrame = hit.CFrame,
            Size = collectableSize,
        })

        Remotes.fireServer("SledRaceCollectableCollected", collectable)
        if SledRaceUtil.collectableIsA(collectable, "Obstacle") then
            -- Determine how head on the collision was
            local collisionOffset = physicsPart.CFrame:PointToObjectSpace(collectableCFrame.Position) * Vector3.new(1, 0, -1)
            local assemblyMass = ModelUtil.getAssemblyMass(collectable)
            local hitDirectness = 1 - math.abs(math.atan2(collisionOffset.X, collisionOffset.Z)) / math.pi
            local heavyness = math.min(1, assemblyMass / MAX_OBSTACLE_MASS)

            physicsPart:ApplyAngularImpulse(
                math.sign(physicsPart.AssemblyAngularVelocity.Y) * Vector3.new(0, 5 + (5 * heavyness), 0) * physicsPart.Mass
            )

            DrivingController.disableControlledSteering(collectable, heavyness)
            DrivingController.applySpeedModifier(-SledRaceConstants.ObstacleSpeedMinuend)

            -- weigthed sums
            local flingForce =
                MathUtil.map(weighted(0.7, 1 - heavyness) + weighted(0.3, hitDirectness), 0, 1, FLING_FORCE.Min, FLING_FORCE.Max)
            local cameraShakeFactor = weighted(0.3, heavyness) + weighted(0.7, hitDirectness)

            CameraController.shake(cameraShakeFactor)

            local crashSound: Sound = Sound.play("SledCrash", true)
            crashSound.PlaybackSpeed = 1 + (1 - heavyness) * 2
            crashSound.PlayOnRemove = true
            crashSound:Destroy()

            for _, basePart in pairs(collectable:GetDescendants()) do
                if basePart:IsA("BasePart") then
                    local clone: BasePart = basePart:Clone()
                    clone.CanTouch = false
                    clone.CanQuery = false
                    clone.Anchored = false
                    clone:ClearAllChildren()
                    clone.Parent = workspace

                    clone:ApplyImpulseAtPosition(
                        (BasePartUtil.closestPoint(clone, hitbox) - hitbox.Position).Unit * flingForce * clone.Mass,
                        collisionPoint
                    )

                    local tween = TweenService:Create(clone, FLING_TWEEN_INFO, { Transparency = 1 })
                    tween.Completed:Connect(function()
                        clone:Destroy()
                    end)
                    tween:Play()
                end
            end

            collectable:Destroy()
        elseif SledRaceUtil.collectableIsA(collectable, "Boost") then
            Sound.play("SledRaceSpeedBoost")

            DrivingController.applySpeedModifier(SledRaceConstants.BoostSpeedAdded)
            collectable:Destroy()
        elseif SledRaceUtil.collectableIsA(collectable, "Coin") then
            Sound.play("CollectGood")

            collectable.PrimaryPart:Destroy()
            collectable:Destroy()

            local particlePackage = particles.CoinCollect:Clone()
            particlePackage.Position = collisionPoint
            particlePackage.Parent = Workspace

            for _, emitter: ParticleEmitter in pairs(particlePackage.Attachment:GetChildren()) do
                emitter:Emit(random:NextNumber(4, 6))
            end

            local value = SledRaceConstants.CoinValue
            coinsCollected += value
            SledRaceScreen.setCoins(coinsCollected)
            SharedMinigameScreen.textParticle("+" .. SledRaceConstants.CoinValue, Images.Coins.Coin)

            task.wait(2)
            particlePackage:Destroy()
        end
    end)

    SledRaceScreen.setCoins(0)

    return function()
        SledRaceScreen.closeCoins()

        hitbox:Destroy()
        colliding:Disconnect()
    end
end

function SledRaceCollectables.getCoinsCollected()
    return coinsCollected
end

return SledRaceCollectables
