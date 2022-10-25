local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StampButton = require(script.Parent.StampButton)
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 300, 0, 300)
    frame.Parent = target

    local stampButton = StampButton.new(StampUtil.getStampFromId("minigame_pizza_play"))

    stampButton:Mount(frame)
    return function()
        frame:Destroy()
        stampButton:Destroy()
    end
end
