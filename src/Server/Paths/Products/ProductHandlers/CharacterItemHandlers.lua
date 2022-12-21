local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local OutfitConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants.OutfitConstants)
local Output = require(Paths.Shared.Output)

local characterItemProducts = Products.Products.CharacterItem
local handlersById: { [string]: (player: Player) -> nil } = {}

-- Generate handlersById table
for productId, product in pairs(characterItemProducts) do
    local metadata = product.Metadata
    if metadata.CategoryName ~= "Outfit" then
        continue
    end

    -- Write callback
    handlersById[productId] = function(player: Player)
        for itemCategory, itemKeys in pairs(OutfitConstants.Items[metadata.ItemKey].Items) do
            for _, itemKey in pairs(itemKeys) do
                local outfitItemProduct = ProductUtil.getCharacterItemProduct(itemCategory, itemKey)
                if not ProductService.hasProduct(player, outfitItemProduct) then
                    ProductService.addProduct(player, outfitItemProduct)
                end
            end
        end

        Output.doDebug(ProductConstants.DoDebug, ("%s's CharacterItem Outfit product %q handled"):format(productId, player.Name))
    end
end

return handlersById
