local ClothingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

-- clothing_equip
do
    local clothingEquipStamp = StampUtil.getStampFromId("clothing_equip")
    CharacterItemService.ItemEquipped:Connect(function(player: Player, _categoryName: string, _itemName: string)
        StampService.addStamp(player, clothingEquipStamp.Id)
    end)
end

-- clothing_twins
do
    local clothingTwinsStamp = StampUtil.getStampFromId("clothing_twins")
    ZoneService.ZoneChanged:Connect(function(player: Player, _fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
        -- RETURN: Not a room
        if toZone.ZoneType ~= ZoneConstants.ZoneType.Room then
            return
        end

        local playersInToZone = ZoneService.getPlayersInZone(toZone)
        for _, somePlayer in pairs(playersInToZone) do
            if somePlayer ~= player then
                if CharacterItemService.doPlayersHaveMatchingCharacterAppearance(player, somePlayer) then
                    StampService.addStamp(player, clothingTwinsStamp.Id)
                    StampService.addStamp(somePlayer, clothingTwinsStamp.Id)
                end
            end
        end
    end)
end

return ClothingStampAwarders
