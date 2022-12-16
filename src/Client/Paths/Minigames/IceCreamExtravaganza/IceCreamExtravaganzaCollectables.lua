local IceCreamExtravaganzaCollectables = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local Images = require(Paths.Shared.Images.Images)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local CameraController = require(Paths.Client.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaCamera)
local Sound = require(Paths.Shared.Sound)

local SHADOW_TRANSPARENCY = 0.5
local SHADOW_DEPTH = Vector3.new(0, 0.1, 0)

local player = Players.LocalPlayer
local assets: BasePart = Paths.Assets.Minigames.IceCreamExtravaganza

function IceCreamExtravaganzaCollectables.setup()
    local maid = Maid.new()

    local map = MinigameController.getMap()
    local floor: BasePart = map.Floor
    local collectableContainer: Folder = map[IceCreamExtravaganzaConstants.CollectableContainerName]

    local idealSpawnHeight: number = map.CollectableSpawns.WorldPivot.Position.Y
    local floorHeight: number = (floor.Position + floor.Size / 2).Y
    local idealDropDistance: number = idealSpawnHeight - floorHeight
    local idealDropLength: number = idealDropDistance / IceCreamExtravaganzaConstants.DropVelocity

    local drops: { [string]: table } = {}

    local character = player.Character
    local participatingCharacters: { Model } = {}
    for _, participant in pairs(MinigameController.getParticpants()) do
        table.insert(participatingCharacters, participant.Character)
    end

    maid:GiveTask(
        Remotes.bindEventTemp("IceCreamExtravaganzaCollectableSpawned", function(id: string, modelTemplate: Model, dropOrigin: CFrame)
            local dropOriginXZ = Vector3Util.getXZComponents(dropOrigin.Position)

            -- Compensate for latency
            -- RETURN: Collectable has already despawned on the server
            local dropLength = idealDropLength - player:GetNetworkPing()
            if dropLength <= 0 then -- Wont happen but why not
                return
            end

            local percentageOfDropRemaining: number = dropLength / idealDropLength
            local percentageOfDropUsed: number = 1 - percentageOfDropRemaining

            -- Collectable
            local model: Model = modelTemplate:Clone()
            local modelSize: Vector3 = model:GetExtentsSize()
            local modelCFrame: CFrame = CFrame.new(dropOriginXZ)
                * CFrame.new(0, idealSpawnHeight - (percentageOfDropUsed * idealDropDistance), 0)
                * dropOrigin.Rotation

            local modelPrimary: BasePart = model.PrimaryPart
            modelPrimary.Anchored = true
            model.Name = id
            model:PivotTo(ModelUtil.getWorldPivotToCenter(modelTemplate, modelCFrame))
            model.Parent = collectableContainer

            local hitbox: Part = Instance.new("Part")
            hitbox.Transparency = 1
            hitbox.Size = modelSize
            hitbox.CFrame = modelCFrame
            hitbox.Massless = true
            hitbox.CanCollide = false
            hitbox.Parent = model
            BasePartUtil.weld(hitbox, modelPrimary)

            local collisionConnection: RBXScriptConnection
            collisionConnection = hitbox.Touched:Connect(function(hit)
                local characterHit: Model
                for _, participatingCharacter in pairs(participatingCharacters) do
                    if hit:IsDescendantOf(participatingCharacter) then
                        characterHit = participatingCharacter
                        break
                    end
                end

                if characterHit then
                    drops[id]:cancel()
                    collisionConnection:Disconnect()

                    if characterHit == character then
                        local collectableType = model:GetAttribute("Type")
                        if collectableType == "Obstacle" then
                            for _ = 1, 2 do
                                SharedMinigameScreen.textParticle("OOF!", nil, Color3.fromRGB(255, 90, 90))
                            end
                            CameraController.shake()

                            Sound.play("CollectBad")
                        else
                            if collectableType == "Regular" then
                                SharedMinigameScreen.textParticle("+1", Images.IceCreamExtravaganza.ConeIcon, nil, modelPrimary.Color)
                            elseif collectableType == "Double" then
                                SharedMinigameScreen.textParticle("+2", Images.IceCreamExtravaganza.ConeIcon, nil, modelPrimary.Color)
                            end

                            Sound.play("CollectGood")
                        end

                        Remotes.fireServer("IceCreamExtravaganzaCollectableCollected", id)
                    end
                end
            end)

            -- Shadow
            local shadowTweenInfo = TweenInfo.new(dropLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local goalShadowSize: Vector3 = Vector3.new(1, 0, 1) * math.max(modelSize.X, modelSize.Z) + SHADOW_DEPTH

            local shadowPart: BasePart = assets.CollectableShadow:Clone()
            shadowPart.Size = (goalShadowSize - SHADOW_DEPTH) * Vector3.new(percentageOfDropUsed, 0, percentageOfDropUsed)
            shadowPart.Position = dropOriginXZ + Vector3.new(0, (floorHeight - SHADOW_DEPTH.Y / 2) + 0.1, 0)
            shadowPart.Parent = Workspace

            local shadowDecal: Decal = shadowPart.Decal
            shadowDecal.Transparency = 1 - (1 - SHADOW_TRANSPARENCY) * percentageOfDropUsed

            -- Drop
            drops[id] = TweenUtil.batch({
                TweenService:Create(shadowPart, shadowTweenInfo, { Size = goalShadowSize }),
                TweenService:Create(shadowDecal, shadowTweenInfo, { Transparency = SHADOW_TRANSPARENCY }),
                TweenService:Create(modelPrimary, TweenInfo.new(dropLength, Enum.EasingStyle.Linear), {
                    CFrame = ModelUtil.getWorldPivotToCenter(
                        model,
                        CFrame.new(0, -idealDropDistance * percentageOfDropRemaining, 0) * model.WorldPivot
                    ),
                }),
            }):finally(function()
                maid:RemoveTask()

                model:Destroy()
                shadowPart:Destroy()

                drops[id] = nil
            end)

            maid:GiveTask(function()
                local tweenPromise = drops[id]
                if tweenPromise then
                    tweenPromise:cancel()
                end
            end)
        end)
    )

    return maid
end

return IceCreamExtravaganzaCollectables
