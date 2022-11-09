local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local VehicleConstants = require(ReplicatedStorage.Shared.Constants.VehicleConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for vehicleName, _vehicleConstants in pairs(VehicleConstants) do
    -- Create Product
    local productId = ("vehicle_%s"):format(StringUtil.toCamelCase(vehicleName))
    local product: Product = {
        Id = productId,
        Type = ProductConstants.ProductType.Vehicle,
        DisplayName = StringUtil.getFriendlyString(vehicleName),
        ImageId = Images.Icons.Hoverboard,
        CoinData = {
            Cost = 1,
        },
        Metadata = {
            VehicleName = vehicleName,
        },
    }

    products[productId] = product
end

return products
