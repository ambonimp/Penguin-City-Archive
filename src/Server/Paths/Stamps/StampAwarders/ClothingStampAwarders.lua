local ClothingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

-- clothing_equip
do
    local clothingEquipStamp = StampUtil.getStampFromId("clothing_equip")
    CharacterItemService.ItemEquipped:Connect(function(player: Player, _categoryName: string, _itemName: string)
        StampService.addStamp(player, clothingEquipStamp.Id)
    end)
end

return ClothingStampAwarders
