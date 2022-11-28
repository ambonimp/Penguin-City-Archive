local DiscoController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local Maid = require(Paths.Packages.maid)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local DISCO_COLORS = {
    Color3.fromRGB(13, 105, 172),
    Color3.fromRGB(167, 0, 125),
    Color3.fromRGB(91, 154, 76),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(107, 50, 124),
    Color3.fromRGB(167, 114, 47),
    Color3.fromRGB(167, 0, 0),
}
local FLASH_NEW_DISCO_COLOR_EVERY = 0.7
local FLASH_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local zoneUpdateMaid = Maid.new()
local colorParts: { [BasePart]: number } = {} -- Values are index offset

local function onZoneUpdate()
    zoneUpdateMaid:Cleanup()

    -- ColorParts
    do
        -- Cache Cleanup
        zoneUpdateMaid:GiveTask(function()
            colorParts = {}
        end)

        -- Disco Balls
        local discoBalls: { Model } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.DiscoBall)
        for _, discoBall in pairs(discoBalls) do
            -- Get ColorParts
            local discoBallColorParts: { BasePart } = {}
            for _, descendant in pairs(discoBall:GetDescendants()) do
                if descendant.Name == ZoneConstants.Cosmetics.Disco.ColorPartName then
                    table.insert(discoBallColorParts, descendant)
                end
            end

            -- Flash
            for i, colorPart in pairs(discoBallColorParts) do
                colorParts[colorPart] = i
            end
        end

        -- Flash
        if not TableUtil.isEmpty(colorParts) then
            local nextFlashAtTick = 0
            local flashCount = 0
            zoneUpdateMaid:GiveTask(RunService.Stepped:Connect(function(_dt)
                -- RETURN: Don't flash yet
                if tick() < nextFlashAtTick then
                    return
                end
                nextFlashAtTick = tick() + FLASH_NEW_DISCO_COLOR_EVERY
                flashCount += 1

                for colorPart, indexOffset in pairs(colorParts) do
                    local index = MathUtil.wrapAround(flashCount + indexOffset, #DISCO_COLORS)
                    TweenUtil.tween(colorPart, FLASH_TWEEN_INFO, {
                        Color = DISCO_COLORS[index],
                    })
                end
            end))
        end
    end
end

ZoneController.ZoneChanged:Connect(function(_fromZone: ZoneConstants.Zone, _toZone: ZoneConstants.Zone)
    onZoneUpdate()
end)
onZoneUpdate()

return DiscoController
