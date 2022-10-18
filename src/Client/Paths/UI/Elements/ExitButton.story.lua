local ExitButton = require(script.Parent.ExitButton)

return function(target)
    local frame = Instance.new("ImageButton")
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(50, 50)
    frame.Parent = target

    local button = ExitButton.new()
    button:Mount(frame, true)
    button.InternalRelease:Connect(function()
        print("Whoa")
    end)

    return function()
        frame:Destroy()
    end
end
