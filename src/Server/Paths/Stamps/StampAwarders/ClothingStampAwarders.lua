local ClothingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ProductService = require(Paths.Server.Products.ProductService)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

-- clothing_equip
local clothingEquipStamp = StampUtil.getStampFromId("clothing_equip")
CharacterItemService.ItemEquipped:Connect(function(player: Player, _categoryName: string, _itemName: string)
    StampService.addStamp(player, clothingEquipStamp.Id)
end)

--!! DISABLED for now
-- -- clothing_twins
-- local clothingTwinsStamp = StampUtil.getStampFromId("clothing_twins")
-- ZoneService.ZoneChanged:Connect(function(player: Player, _fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
--     -- RETURN: Not a room
--     if toZone.ZoneType ~= ZoneConstants.ZoneType.Room then
--         return
--     end

--     local playersInToZone = ZoneService.getPlayersInZone(toZone)
--     for _, somePlayer in pairs(playersInToZone) do
--         if somePlayer ~= player then
--             if CharacterItemService.doPlayersHaveMatchingCharacterAppearance(player, somePlayer) then
--                 StampService.addStamp(player, clothingTwinsStamp.Id)
--                 StampService.addStamp(somePlayer, clothingTwinsStamp.Id)
--             end
--         end
--     end
-- end)

-- clothing_items25, clothing_items100
local clothingItems25Stamp = StampUtil.getStampFromId("clothing_items25")
local clothingItems100Stamp = StampUtil.getStampFromId("clothing_items100")
ProductService.ProductAdded:Connect(function(player: Player, product: Products.Product, _amount: number)
    -- RETURN: Non-character item product added
    if not ProductUtil.isCharacterItemProduct(product) then
        return
    end

    -- Total up clothing items owned
    local totalClothingItems = 0
    for someProduct, _ in pairs(ProductService.getOwnedProducts(player)) do
        if ProductUtil.isCharacterItemProduct(someProduct) then
            totalClothingItems += 1
        end
    end

    -- Award
    if totalClothingItems >= 25 then
        StampService.addStamp(player, clothingItems25Stamp.Id)
    end

    if totalClothingItems >= 100 then
        StampService.addStamp(player, clothingItems100Stamp.Id)
    end
end)

return ClothingStampAwarders
