local RadialMenu = require(script.Parent.RadialMenu)

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 300, 0, 300)
    frame.Parent = target

    local radialMenu = RadialMenu.new()

    local count = 0
    local function addButton()
        count += 1
        local button = radialMenu:AddButton()
        button:SetText(tostring(count))
        button.Pressed:Connect(addButton)
    end
    addButton()

    radialMenu:Mount(frame)
    return function()
        frame:Destroy()
        radialMenu:Destroy()
    end
end
