local PetEggInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductController = require(Paths.Client.ProductController)

InteractionController.registerInteraction("PetEgg", function(instance)
    ProductController.prompt(ProductUtil.getPetEggProduct(instance.Name:gsub("Egg", "")))
end, "Buy Egg")

return PetEggInteraction
