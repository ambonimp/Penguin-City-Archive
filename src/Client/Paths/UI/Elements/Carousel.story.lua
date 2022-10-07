local Carousel = require(script.Parent.Carousel)

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 100, 1)
    frame.Parent = target

    local carousel = Carousel.new()
    carousel:SetNavigatorSize(30)

    for i = 1, 15 do
        local name = tostring(i)

        local child = Instance.new("TextButton")
        child.Rotation = 25
        child.Name = name
        child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        child.Size = UDim2.fromScale(1, 1)
        child.Text = name
        child.SizeConstraint = Enum.SizeConstraint.RelativeXX

        carousel:MountChild(child)
    end

    carousel:Mount(frame)
    return function()
        frame:Destroy()
        carousel:Destroy()
    end
end
