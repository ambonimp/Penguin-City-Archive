local DiscoController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Maid = require(Paths.Packages.maid)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local PlayersHitbox = require(Paths.Shared.PlayersHitbox)
local PetController = require(Paths.Client.Pets.PetController)
local PetConstants = require(Paths.Shared.Pets.PetConstants)

local DISCO_COLORS = {
    Color3.fromRGB(13, 105, 172),
    Color3.fromRGB(167, 0, 125),
    Color3.fromRGB(91, 154, 76),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(107, 50, 124),
    Color3.fromRGB(167, 114, 47),
    Color3.fromRGB(167, 0, 0),
}
local FLASH_NEW_DISCO_COLOR_EVERY = 1.5
local FLASH_TWEEN_INFO = TweenInfo.new(0.05)
local DISCO_BALL_ROTATION_PER_SECOND = 45

local colorParts: { [BasePart]: number } = {} -- Values are index offset

function DiscoController.onZoneUpdate(maid: typeof(Maid.new()), _zone: ZoneConstants.Zone, zoneModel: Model)
    -- ColorParts
    do
        -- Cache Cleanup
        maid:GiveTask(function()
            colorParts = {}
        end)

        -- Disco Balls
        local discoBalls: { Model } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.DiscoBall)
        for _, discoBall in pairs(discoBalls) do
            -- Get ColorParts
            local discoBallColorParts: { BasePart } = {}
            for _, descendant in pairs(discoBall:GetDescendants()) do
                if string.find(descendant.Name, ZoneConstants.Cosmetics.Disco.ColorPartName) then
                    table.insert(discoBallColorParts, descendant)
                end
            end

            -- Flash
            for i, colorPart in pairs(discoBallColorParts) do
                colorParts[colorPart] = i
            end
        end

        -- Dance Floors
        local danceFloors: { Model } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.DanceFloor)
        for _, danceFloor in pairs(danceFloors) do
            -- Get ColorParts
            local danceFloorColorParts: { BasePart } = {}
            for _, descendant in pairs(danceFloor:GetDescendants()) do
                if string.find(descendant.Name, ZoneConstants.Cosmetics.Disco.ColorPartName) then
                    table.insert(danceFloorColorParts, descendant)
                end
            end

            -- Flash
            for i, colorPart in pairs(danceFloorColorParts) do
                colorParts[colorPart] = i
            end
        end

        -- Flash
        if not TableUtil.isEmpty(colorParts) then
            local nextFlashAtTick = 0
            local flashCount = 0
            maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
                -- Rotate DiscoBalls
                for _, discoBall in pairs(discoBalls) do
                    local rotatedPivot = discoBall:GetPivot() * CFrame.Angles(0, math.rad(DISCO_BALL_ROTATION_PER_SECOND * dt), 0)
                    discoBall:PivotTo(rotatedPivot)
                end

                -- Flash
                local doFlash = tick() >= nextFlashAtTick
                if doFlash then
                    nextFlashAtTick = tick() + FLASH_NEW_DISCO_COLOR_EVERY
                    flashCount += 1

                    for colorPart, indexOffset in pairs(colorParts) do
                        local index = MathUtil.wrapAround(flashCount + indexOffset, #DISCO_COLORS)
                        TweenUtil.tween(colorPart, FLASH_TWEEN_INFO, {
                            Color = DISCO_COLORS[index],
                        })
                    end
                end
            end))
        end
    end

    -- Dance Floor dancing
    do
        -- Setup detection for being on dancefloor + triggering dancing
        local danceFloorHitbox = PlayersHitbox.new()
        maid:GiveTask(danceFloorHitbox)

        danceFloorHitbox.PlayerEntered:Connect(function(player)
            -- RETURN: Not local player
            if player ~= Players.LocalPlayer then
                return
            end

            -- Pet Animation
            local clientPet = PetController.getClientPet()
            if clientPet then
                clientPet:PlayAnimation(PetConstants.AnimationNames.Trick)
            end
        end)
        danceFloorHitbox.PlayerLeft:Connect(function(player)
            -- RETURN: Not local player
            if player ~= Players.LocalPlayer then
                return
            end

            -- Pet Animation
            local clientPet = PetController.getClientPet()
            if clientPet then
                clientPet:StopAnimation(PetConstants.AnimationNames.Trick)
            end
        end)

        -- Iterate DanceFloors
        local danceFloors: { Model } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.DanceFloor)
        for _, danceFloor in pairs(danceFloors) do
            if danceFloor:IsDescendantOf(zoneModel) then
                -- DanceFloor Detection
                local hitboxPart: BasePart = danceFloor.Hitbox
                danceFloorHitbox:AddPart(hitboxPart)
            end
        end
    end
end

return DiscoController
