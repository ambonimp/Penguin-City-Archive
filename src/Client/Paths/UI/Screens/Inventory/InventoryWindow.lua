local InventoryWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Maid = require(Paths.Packages.maid)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local TitledWindow = require(Paths.Client.UI.Elements.TitledWindow)

local GRID_SIZE = Vector2.new(5, 3)
local EQUIPPED_COLOR = Color3.fromRGB(0, 165, 0)

--[[
    data:
    - `AddCallback`: If passed, will create an "Add" button that will invoke AddCallback

    Equipping
    - `Equip`: Called with `EquipValue` when we press a non-equipped widget. Must immediately update the return value of `GetEquipped`
    - `Unequip`: Called with `EquipValue` when we press an equipped wiget. Must immediately update the return value of `GetEquipped`
    - `GetEquipped`: Returns an array of `EquipValue` - this is how we gauge if a widget is equipped or not
]]
function InventoryWindow.new(
    icon: string,
    title: string,
    data: {
        AddCallback: (() -> nil)?,
        Equipping: {
            Equip: (value: any) -> nil,
            Unequip: ((value: any) -> nil),
            GetEquipped: () -> { any },
        }?,
    }
)
    local inventoryWindow = TitledWindow.new(icon, title)
    local maid = inventoryWindow:GetMaid()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local inventoryWindowFrame = inventoryWindow:GetWindowHolder()

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

    widgets.Parent = inventoryWindowFrame

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

    leftArrowFrame.Parent = inventoryWindowFrame

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

    rightArrowFrame.Parent = inventoryWindowFrame
    --#endregion

    local drawMaid = Maid.new()
    maid:GiveTask(drawMaid)

    local pageNumber = 1

    local leftArrow = AnimatedButton.new(leftArrowButton)
    maid:GiveTask(leftArrow)
    local rightArrow = AnimatedButton.new(rightArrowButton)
    maid:GiveTask(rightArrow)

    local currentPopulateData: { {
        WidgetConstructor: () -> typeof(Widget.diverseWidget()),
        EquipValue: any | nil,
    } } =
        {}

    local addCallback = data.AddCallback
    local equipping = data.Equipping

    local totalWidgetsPerPage = GRID_SIZE.X * GRID_SIZE.Y - (addCallback and 1 or 0) -- -1 for add widget

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
        local equippedValues = equipping and equipping.GetEquipped()
        for i, entry in pairs(visibleEntries) do
            local holder = getHolderFrame(i)
            drawMaid:GiveTask(holder)

            local widget = entry.WidgetConstructor()
            widget:Mount(holder)
            widget.Pressed:Connect(function()
                if equipping and entry.EquipValue ~= nil then
                    inventoryWindow:EquipToggle(entry.EquipValue)
                end
            end)

            if equipping then
                if entry.EquipValue ~= nil and table.find(equippedValues, entry.EquipValue) then
                    widget:SetOutline(EQUIPPED_COLOR)
                    holder.LayoutOrder = 0 -- Near the top
                end
            end

            drawMaid:GiveTask(widget)
        end

        -- Pages
        inventoryWindow:SetSubText(("Page %d/%d"):format(pageNumber, getMaxPageNumber()))

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
        -- Ensure unique EquipValue (if equipping is enabled)
        if equipping then
            local equipValuesCache: { [any]: true } = {}
            local startingEquippedValues = equipping.GetEquipped()
            local startingEquippedIndexes: { number } = {}
            for i, entry in pairs(populateData) do
                if entry.EquipValue ~= nil then
                    if equipValuesCache[entry.EquipValue] then
                        warn(("Duplicate equip value %q"):format(tostring(entry.EquipValue)))
                    end
                    if equipping and table.find(startingEquippedValues, entry.EquipValue) then
                        table.insert(startingEquippedIndexes, i)
                    end

                    equipValuesCache[entry.EquipValue] = true
                end
            end

            -- Move equipped data to the front
            do
                -- Remove in reverse order from populateData to ensyure indexes don't shift
                local equippedEntries: { typeof(populateData[1]) } = {}
                for j = #startingEquippedIndexes, 1, -1 do
                    local index = startingEquippedIndexes[j]
                    local entry = populateData[index]
                    table.remove(populateData, index)
                    table.insert(equippedEntries, entry)
                end

                -- Reinsert back at beginning
                for _, entry in pairs(equippedEntries) do
                    table.insert(populateData, 1, entry)
                end
            end
        end

        -- Init data + page
        currentPopulateData = populateData
        pageNumber = 1

        -- Draw
        draw()
    end

    --[[
        If `isExternal=true`, this is a call informing this UI the equipped value has been changed externally (e.g., `mountHoverboard` command).
    ]]
    function inventoryWindow:EquipToggle(equipValue: any)
        -- WARN: No equipping!
        if not equipping then
            warn("No equipping data")
            return
        end

        local equippedValues = equipping.GetEquipped()
        local isEquipped = table.find(equippedValues, equipValue) and true or false

        if isEquipped then
            equipping.Unequip(equipValue)
        else
            equipping.Equip(equipValue)
        end

        draw()
    end

    function inventoryWindow:GetWindowFrame()
        return inventoryWindowFrame
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
