local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ImageViewer = require(Paths.Client.Images.ImageViewer)

return function()
    ImageViewer.viewImages()
end
