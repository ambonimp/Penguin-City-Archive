local InventoryWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Maid = require(Paths.Packages.maid)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIElement = require(Paths.Client.UI.Elements.UIElement)

local GRID_SIZE = Vector2.new(5, 3)
local EQUIPPED_COLOR = Color3.fromRGB(0, 165, 0)

--[[
    data:
    - AddCallback: If passed, will create an "Add" button that will invoke AddCallback
]]
function InventoryWindow.new(
    icon: string,
    title: string,
    data: {
        AddCallback: (() -> nil)?,
        Equipping: {
            Equip: (value: any) -> nil,
            Unequip: ((value: any) -> nil)?,
            StartEquipped: any?,
        }?,
    }
)
    local inventoryWindow = UIElement.new()
    local maid = inventoryWindow:GetMaid()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local inventoryWindowFrame = Instance.new("Frame")
    inventoryWindowFrame.Name = "inventoryWindowFrame"
    inventoryWindowFrame.BackgroundTransparency = 1
    inventoryWindowFrame.Size = UDim2.fromScale(1, 1)
    maid:GiveTask(inventoryWindowFrame)

    local top = Instance.new("Frame")
    top.Name = "top"
    top.BackgroundTransparency = 1
    top.Size = UDim2.fromScale(1, 0.2)

    local topIcon = Instance.new("ImageLabel")
    topIcon.Name = "topIcon"
    topIcon.Image = "rbxassetid://11505043486"
    topIcon.AnchorPoint = Vector2.new(0, 0.5)
    topIcon.BackgroundTransparency = 1
    topIcon.Position = UDim2.fromScale(0.05, 0.5)
    topIcon.Size = UDim2.fromOffset(130, 130)
    topIcon.ScaleType = Enum.ScaleType.Fit
    topIcon.Parent = top

    local topTitle = Instance.new("TextLabel")
    topTitle.Name = "topTitle"
    topTitle.Font = UIConstants.Font
    topTitle.Text = "Hoverboards"
    topTitle.TextColor3 = Color3.fromRGB(38, 71, 118)
    topTitle.TextSize = 80
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.AnchorPoint = Vector2.new(0, 0.5)
    topTitle.BackgroundTransparency = 1
    topTitle.Position = UDim2.new(0.05, 140, 0.5, 0)
    topTitle.Size = UDim2.fromScale(0.4, 1)
    topTitle.Parent = top

    local topPage = Instance.new("TextLabel")
    topPage.Name = "topPage"
    topPage.Font = UIConstants.Font
    topPage.Text = "Page 1/1"
    topPage.TextColor3 = Color3.fromRGB(38, 71, 118)
    topPage.TextSize = 40
    topPage.TextXAlignment = Enum.TextXAlignment.Right
    topPage.TextYAlignment = Enum.TextYAlignment.Bottom
    topPage.AnchorPoint = Vector2.new(1, 1)
    topPage.BackgroundTransparency = 1
    topPage.Position = UDim2.fromScale(0.95, 0.95)
    topPage.Size = UDim2.fromScale(0.4, 0.2)
    topPage.Parent = top

    top.Parent = inventoryWindowFrame

    local divider = Instance.new("Frame")
    divider.Name = "divider"
    divider.AnchorPoint = Vector2.new(0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(219, 236, 255)
    divider.Position = UDim2.fromScale(0.5, 0.2)
    divider.Size = UDim2.fromScale(0.9, 0.01)

    local dividerCorner = Instance.new("UICorner")
    dividerCorner.Name = "dividerCorner"
    dividerCorner.CornerRadius = UDim.new(0, 100)
    dividerCorner.Parent = divider

    divider.Parent = inventoryWindowFrame

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bottom.BackgroundTransparency = 1
    bottom.Position = UDim2.fromScale(0, 0.22)
    bottom.Size = UDim2.fromScale(1, 0.77)

    local widgets = Instance.new("Frame")
    widgets.Name = "widgets"
    widgets.AnchorPoint = Vector2.new(0.5, 0.5)
    widgets.BackgroundTransparency = 1
    widgets.Position = UDim2.fromScale(0.5, 0.5)
    widgets.Size = UDim2.new(1, -140, 1, 0)

    local widgetsGridLayout = Instance.new("UIGridLayout")
    widgetsGridLayout.Name = "widgetsGridLayout"
    widgetsGridLayout.CellPadding = UDim2.new()
    widgetsGridLayout.CellSize = UDim2.new(1 / GRID_SIZE.X, -1, 1 / GRID_SIZE.Y, -1)
    widgetsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    widgetsGridLayout.Parent = widgets

    widgets.Parent = bottom

    local leftArrowFrame = Instance.new("Frame")
    leftArrowFrame.Name = "leftArrowFrame"
    leftArrowFrame.AnchorPoint = Vector2.new(0, 0.5)
    leftArrowFrame.BackgroundTransparency = 1
    leftArrowFrame.Position = UDim2.fromScale(0, 0.5)
    leftArrowFrame.Size = UDim2.fromOffset(60, 100)

    local leftArrowButton = Instance.new("ImageButton")
    leftArrowButton.Name = "leftArrowButton"
    leftArrowButton.Image = "rbxassetid://11252199030"
    leftArrowButton.ScaleType = Enum.ScaleType.Fit
    leftArrowButton.BackgroundTransparency = 1
    leftArrowButton.Size = UDim2.fromScale(1, 1)
    leftArrowButton.Parent = leftArrowFrame

    leftArrowFrame.Parent = bottom

    local rightArrowFrame = Instance.new("Frame")
    rightArrowFrame.Name = "rightArrowFrame"
    rightArrowFrame.AnchorPoint = Vector2.new(1, 0.5)
    rightArrowFrame.BackgroundTransparency = 1
    rightArrowFrame.Position = UDim2.fromScale(1, 0.5)
    rightArrowFrame.Size = UDim2.fromOffset(60, 100)

    local rightArrowButton = Instance.new("ImageButton")
    rightArrowButton.Name = "rightArrowButton"
    rightArrowButton.Image = "rbxassetid://11252175153"
    rightArrowButton.ScaleType = Enum.ScaleType.Fit
    rightArrowButton.BackgroundTransparency = 1
    rightArrowButton.Size = UDim2.fromScale(1, 1)
    rightArrowButton.Parent = rightArrowFrame

    rightArrowFrame.Parent = bottom

    bottom.Parent = inventoryWindowFrame
    --#endregion

    local drawMaid = Maid.new()
    maid:GiveTask(drawMaid)

    local pageNumber = 1

    local leftArrow = AnimatedButton.new(leftArrowButton)
    maid:GiveTask(leftArrow)
    local rightArrow = AnimatedButton.new(rightArrowButton)
    maid:GiveTask(rightArrow)

    topIcon.Image = icon
    topTitle.Text = title

    local currentPopulateData: { {
        WidgetConstructor: () -> typeof(Widget.diverseWidget()),
        EquipValue: any | nil,
    } } =
        {}
    local widgetsByEquipValue: { [any]: typeof(Widget.diverseWidget()) } = {}

    local addCallback = data.AddCallback
    local equipping = data.Equipping

    local totalWidgetsPerPage = GRID_SIZE.X * GRID_SIZE.Y - (addCallback and 1 or 0) -- -1 for add widget
    local equippedValue: any | nil

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function getMaxPageNumber()
        return math.clamp(math.ceil(#currentPopulateData / totalWidgetsPerPage), 1, math.huge)
    end

    local function getHolderFrame(layoutOrder: number)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = layoutOrder
        holder.Parent = widgets
        return holder
    end

    local function draw()
        drawMaid:Cleanup()

        -- Grab entries to show on the current page
        local pageIndexContext = (pageNumber - 1) * totalWidgetsPerPage
        local visibleEntries: typeof(currentPopulateData) = {}
        for i = 1 + pageIndexContext, totalWidgetsPerPage + pageIndexContext do
            local entry = currentPopulateData[i]
            if entry then
                table.insert(visibleEntries, entry)
            else
                break
            end
        end

        -- Add Widget
        if addCallback then
            local holder = getHolderFrame(-1)
            drawMaid:GiveTask(holder)

            local addWidget = Widget.addWidget()
            addWidget:Mount(holder)
            addWidget.Pressed:Connect(addCallback)

            drawMaid:GiveTask(addWidget)
        end

        -- Widgets
        widgetsByEquipValue = {}
        for i, entry in pairs(visibleEntries) do
            local holder = getHolderFrame(i)
            drawMaid:GiveTask(holder)

            local widget = entry.WidgetConstructor()
            widget:Mount(holder)
            widget.Pressed:Connect(function()
                if equipping then
                    if entry.EquipValue == equippedValue then
                        inventoryWindow:Equip(nil)
                    elseif entry.EquipValue ~= nil then
                        inventoryWindow:Equip(entry.EquipValue)
                    end
                end
            end)

            if entry.EquipValue ~= nil then
                if entry.EquipValue == equippedValue then
                    widget:SetOutline(EQUIPPED_COLOR)
                    holder.LayoutOrder = 0 -- Near the top
                end

                widgetsByEquipValue[entry.EquipValue] = widget
            end
            drawMaid:GiveTask(widget)
        end

        -- Pages
        topPage.Text = ("Page %d/%d"):format(pageNumber, getMaxPageNumber())

        -- Arrows
        leftArrowButton.Visible = pageNumber > 1
        rightArrowButton.Visible = pageNumber < getMaxPageNumber()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function inventoryWindow:Populate(populateData: { {
        WidgetConstructor: () -> typeof(Widget.diverseWidget()),
        EquipValue: any | nil,
    } })
        -- Ensure unique EquipValue
        local equipValues: { [any]: true } = {}
        local startEquippedIndex: number | nil
        for i, entry in pairs(populateData) do
            if entry.EquipValue ~= nil then
                if equipValues[entry.EquipValue] then
                    warn(("Duplicate equip value %q"):format(tostring(entry.EquipValue)))
                end
                if equipping and equipping.StartEquipped == entry.EquipValue then
                    startEquippedIndex = i
                end

                equipValues[entry.EquipValue] = true
            end
        end

        -- Move equipped data to the front
        if startEquippedIndex then
            local equippedEntry = populateData[startEquippedIndex]
            table.remove(populateData, startEquippedIndex)
            table.insert(populateData, 1, equippedEntry)
        end

        -- Init data + page
        currentPopulateData = populateData
        pageNumber = 1

        -- Start Equipped
        if equipping and equipping.StartEquipped then
            equippedValue = equipping.StartEquipped
        end

        -- Draw
        draw()
    end

    --[[
        If `isExternal=true`, this is a call informing this UI the equipped value has been changed externally (e.g., `mountHoverboard` command).
    ]]
    function inventoryWindow:Equip(newEquipValue: any | nil, isExternal: boolean?)
        -- WARN: No equipping!
        if not equipping then
            warn("No equipping data")
            return
        end

        -- RETURN: No Change
        if equippedValue == newEquipValue then
            return
        end

        if not isExternal then
            if equippedValue ~= nil and equipping.Unequip then
                task.spawn(equipping.Unequip, equippedValue)
            end

            if newEquipValue ~= nil then
                task.spawn(equipping.Equip, newEquipValue)
            end
        end

        equippedValue = newEquipValue

        draw()
    end

    function inventoryWindow:GetWindowFrame()
        return inventoryWindowFrame
    end

    function inventoryWindow:Mount(parent: GuiObject)
        inventoryWindowFrame.Parent = parent
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Navigation
    leftArrow.Pressed:Connect(function()
        if pageNumber > 1 then
            pageNumber -= 1
            draw()
        end
    end)
    rightArrow.Pressed:Connect(function()
        if pageNumber + 1 <= getMaxPageNumber() then
            pageNumber += 1
            draw()
        end
    end)

    return inventoryWindow
end

return InventoryWindow
