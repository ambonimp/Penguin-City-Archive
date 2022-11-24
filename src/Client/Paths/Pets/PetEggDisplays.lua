--[[
    Handles the PetEgg BillboardGuis that show % chances, and prompts the user to purchase
]]
local PetEggDisplays = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local Maid = require(Paths.Packages.maid)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ModelUtil = require(Paths.Shared.Utils.ModelUtil)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local ProductController = require(Paths.Client.ProductController)

local WIDGET_RESOLUTION = UDim2.fromOffset(123, 123)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

local updateMaid = Maid.new()

function PetEggDisplays.createDisplay(petEggName: string, displayPart: BasePart)
    local product = ProductUtil.getPetEggProduct(petEggName)

    -- UI
    do
        -- Setup BillboardGui
        local billboardGui: BillboardGui = ReplicatedStorage.Templates.Pets.PetEggDisplay:Clone()
        billboardGui.Adornee = displayPart
        billboardGui.Parent = Paths.UI
        updateMaid:GiveTask(billboardGui)

        local petsFrame: Frame = billboardGui.Back.Contents.Pets
        local eggImageLabel: ImageLabel = billboardGui.Back.Contents.Top.EggImage
        local eggTextLabel: TextLabel = billboardGui.Back.Contents.Top.EggName

        local template: Frame = petsFrame.template
        template.BackgroundTransparency = 1
        template.Holder.BackgroundTransparency = 1

        -- Populate Pet Egg name + Image
        eggImageLabel.Image = product.ImageId or ""
        eggImageLabel.ImageColor3 = product.ImageColor or COLOR_WHITE

        eggTextLabel.Text = product.DisplayName

        -- Sort pet entries by largest weight to smallest
        local totalWeight = 0
        local sortedPetEntries = false and PetConstants.PetEggs[petEggName].WeightTable or {} -- Only way I could get intellisense to work
        for _, petEntry in pairs(PetConstants.PetEggs[petEggName].WeightTable) do
            totalWeight += petEntry.Weight

            local isInserted = false
            for i, somePetEntry in pairs(sortedPetEntries) do
                if somePetEntry.Weight < petEntry.Weight then
                    table.insert(sortedPetEntries, i, petEntry)
                    isInserted = true
                    break
                end
            end

            if not isInserted then
                table.insert(sortedPetEntries, petEntry)
            end
        end

        -- Create + Mount widgets
        for i, petEntry in pairs(sortedPetEntries) do
            -- UI Holder
            local frame = template:Clone()
            frame.LayoutOrder = i
            frame.Name = tostring(i)
            frame.Parent = petsFrame

            -- % Chance Label
            local percentChance = 100 * (petEntry.Weight / totalWeight)
            local displayPercent: string
            if percentChance > 5 then
                displayPercent = ("%d"):format(percentChance)
            elseif percentChance >= 1 then
                displayPercent = ("%.1f"):format(percentChance)
            else
                displayPercent = ("%.2f"):format(percentChance)
            end
            displayPercent = ("%s%%"):format(displayPercent)

            -- Widget
            local widget = Widget.diverseWidgetFromPetTuple(petEntry.Value)
            widget:Mount(frame.Holder)
            widget:SetText(displayPercent)
            UIUtil.convertToScale(widget:GetGuiObject(), WIDGET_RESOLUTION)
            updateMaid:GiveTask(widget)
        end

        template.Visible = false
    end

    -- Model
    local model = ProductUtil.getModel(product):Clone()
    ModelUtil.anchor(model)
    displayPart.Transparency = 1
    model.Parent = displayPart
    model:PivotTo(displayPart:GetPivot())
    updateMaid:GiveTask(model)

    -- Proximity Prompt
    local proximityPrompt = InteractionUtil.createInteraction(displayPart, { ObjectText = product.DisplayName, ActionText = "Purchase" })
    proximityPrompt.Triggered:Connect(function()
        ProductController.prompt(product)
    end)
    updateMaid:GiveTask(proximityPrompt)
end

-- Checks the world for pet eggs, and creates displays if needed
function PetEggDisplays.update()
    updateMaid:Cleanup()

    for petEggName, _ in pairs(PetConstants.PetEggs) do
        local displayName = ("%sPetEgg"):format(petEggName)
        local displayParts: { BasePart } = CollectionService:GetTagged(displayName)
        for _, displayPart in pairs(displayParts) do
            -- ERROR: Not a part!
            if not displayPart:IsA("BasePart") then
                error(("Got a DisplayInstace (%s) that is not a BasePart!"):format(displayPart:GetFullName()))
            end

            PetEggDisplays.createDisplay(petEggName, displayPart)
        end
    end
end

-- Run an update whenever we enter a new zone
ZoneController.ZoneChanged:Connect(PetEggDisplays.update)
PetEggDisplays.update()

return PetEggDisplays
