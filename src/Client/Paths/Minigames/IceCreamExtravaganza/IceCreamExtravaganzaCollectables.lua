local IceCreamExtravaganzaCollectables = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Janitor = require(Paths.Packages.janitor)
local Remotes = require(Paths.Shared.Remotes)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)

local SHADOW_TRANSPARENCY = 0.5
local SHADOW_DEPH = Vector3.new(0, 0.1, 0)

local player = Players.LocalPlayer
local assets: BasePart = Paths.Assets.Minigames.IceCreamExtravaganza

function IceCreamExtravaganzaCollectables.setup()
    local janitor = Janitor.new()

    local map = MinigameController.getMap()
    local floor: BasePart = map.Floor
    local collectableContainer: Folder = map[IceCreamExtravaganzaConstants.CollectableContainerName]

    local idealSpawnHeight: number = map.CollectableSpawns.WorldPivot.Position.Y
    local floorHeight: number = (floor.Position + floor.Size / 2).Y
    local idealDropDistance: number = idealSpawnHeight - floorHeight
    local idealDropLength: number = idealDropDistance / IceCreamExtravaganzaConstants.DropVelocity

    local drops: { [string]: table } = {}

    local character = player.Character
    local characterCFrame, characterSize = character:GetBoundingBox()

    janitor:Add(
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

            local model: Model = modelTemplate:Clone()
            local modelSize: Vector3 = model:GetExtentsSize()
            model.Name = id
            model:PivotTo(
                ModelUtil.getWorldPivotToCenter(
                    modelTemplate,
                    CFrame.new(dropOriginXZ)
                        * CFrame.new(0, idealSpawnHeight - (percentageOfDropUsed * idealDropDistance), 0)
                        * dropOrigin.Rotation
                )
            )
            model.Parent = collectableContainer

            local shadowTweenInfo = TweenInfo.new(dropLength, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            local goalShadowSize: Vector3 = Vector3.new(1, 0, 1) * math.max(modelSize.X, modelSize.Z) + SHADOW_DEPH

            local shadowPart: BasePart = assets.CollectableShadow:Clone()
            shadowPart.Size = (goalShadowSize - SHADOW_DEPH) * Vector3.new(percentageOfDropUsed, 0, percentageOfDropUsed)
            shadowPart.Position = dropOriginXZ + Vector3.new(0, (floorHeight - SHADOW_DEPH.Y / 2) + 0.1, 0)
            shadowPart.Parent = Workspace

            local shadowDecal: Decal = shadowPart.Decal
            shadowDecal.Transparency = 1 - (1 - SHADOW_TRANSPARENCY) * percentageOfDropUsed

            drops[id] = TweenUtil.batch({
                TweenService:Create(shadowPart, shadowTweenInfo, { Size = goalShadowSize }),
                TweenService:Create(shadowDecal, shadowTweenInfo, { Transparency = SHADOW_TRANSPARENCY }),
                TweenService:Create(model.PrimaryPart, TweenInfo.new(dropLength, Enum.EasingStyle.Linear), {
                    CFrame = ModelUtil.getWorldPivotToCenter(
                        model,
                        CFrame.new(0, -idealDropDistance * percentageOfDropRemaining, 0) * model.WorldPivot
                    ),
                }),
            }):finally(function()
                if janitor:Get(id) then
                    janitor:Remove(id)
                end

                model:Destroy()
                shadowPart:Destroy()

                drops[id] = nil
            end)

            janitor:Add(function()
                local tweenPromise = drops[id]
                if tweenPromise then
                    tweenPromise:cancel()
                end
            end, nil, id)
        end)
    )

    local hitbox: Part = Instance.new("Part")
    hitbox.Transparency = 1
    hitbox.Size = characterSize
    hitbox.CFrame = characterCFrame
    hitbox.Massless = true
    hitbox.CanCollide = false
    hitbox.Parent = character
    janitor:Add(hitbox)
    BasePartUtil.weld(hitbox, character.HumanoidRootPart)
    janitor:Add(hitbox.Touched:Connect(function(hit: BasePart)
        -- RETURN: Did not touch a collectable
        if not hit:IsDescendantOf(collectableContainer) then
            return
        end

        local collectableModel = hit
        repeat
            collectableModel = collectableModel.Parent
        until not collectableModel or collectableModel.Parent == collectableContainer

        local collectableId: string = collectableModel.Name
        local collectableType = collectableModel:GetAttribute("Type")

        drops[collectableId]:cancel()

        Remotes.fireServer("IceCreamExtravaganzaCollectableCollected", collectableId)
    end))

    return janitor
end

return IceCreamExtravaganzaCollectables
