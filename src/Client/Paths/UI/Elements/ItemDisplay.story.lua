local ItemDisplay = require(script.Parent.ItemDisplay)

return function(target)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 300, 0, 300)
    frame.Parent = target

    local itemDisplay = ItemDisplay.new()
    itemDisplay:Mount(frame)

    local count = 0
    itemDisplay.Pressed:Connect(function()
        count += 1

        itemDisplay:SetTitle(tostring(count))
        itemDisplay:SetText("number " .. tostring(count))
        itemDisplay:SetTextIcon(math.random() < 0.5 and "rbxassetid://11152355612" or "")
        itemDisplay:SetBorderColor(Color3.fromHSV(math.random(), 1, 1))
        itemDisplay:SetOverlay(math.random() < 0.5 and "Completed" or nil)
    end)

    return function()
        frame:Destroy()
        itemDisplay:Destroy()
    end
end
