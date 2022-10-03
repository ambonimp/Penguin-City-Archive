--[[
    Contains all of our Images in the game
     - Use this file to reference an image via code
     - "Register" any image added into the game
     - --!! Ensure you run any images added here through pixel fix!
]]
local Images = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ImageContexts = Paths.Client.Images.ImageContexts

-- Write ImageContexts
Images.ButtonIcons = require(ImageContexts.ButtonIcons)
Images.Icons = require(ImageContexts.Icons)
Images.Coins = require(ImageContexts.Coins)
Images.PizzaMinigame = require(ImageContexts.PizzaMinigame)

return Images
