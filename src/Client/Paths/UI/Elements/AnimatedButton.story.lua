local Elements = script.Parent
local Button = require(Elements.Button)
local AnimatedButton = require(Elements.AnimatedButton)

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(300, 400)
    frame.Parent = target

    local buttonObject = Instance.new("ImageButton")
    buttonObject.Position = UDim2.fromScale(0.2, 0.5)
    buttonObject.Size = UDim2.fromScale(0.2, 0.2)

    local button = AnimatedButton.new(Button.new(buttonObject))
    button:MountToUnconstrained(frame)
    button:SetHoverAnimation(
        AnimatedButton.combineAnimations({ AnimatedButton.Animations.Squish(UDim2.fromScale(1.2, 1.2)), AnimatedButton.Animations.Nod(25) })
    )

    return function()
        frame:Destroy()
    end
end
