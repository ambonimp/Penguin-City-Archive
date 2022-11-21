--[[
    Class for a BillboardGui nametag
]]
local Nametag = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

local MOUNT_PART_PROPERTIES = {
    CanCollide = false,
    Name = "NametagPart",
    Size = Vector3.new(1, 1, 1),
    Transparency = 1,
}

function Nametag.new()
    local nametag = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local isDestroyed = false

    --#region Create UI
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "billboardGui"
    billboardGui.Active = true
    billboardGui.ClipsDescendants = true
    billboardGui.LightInfluence = 1
    billboardGui.MaxDistance = 70
    billboardGui.Size = UDim2.fromScale(30, 4)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.ResetOnSpawn = false
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local holderFrame = Instance.new("Frame")
    holderFrame.Name = "holderFrame"
    holderFrame.BackgroundTransparency = 1
    holderFrame.Size = UDim2.fromScale(1, 1)

    local uIListLayout = Instance.new("UIListLayout")
    uIListLayout.Name = "uIListLayout"
    uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    uIListLayout.Parent = holderFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "nameLabel"
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = "Nametag"
    nameLabel.TextColor3 = Color3.fromRGB(38, 71, 118)
    nameLabel.TextScaled = true
    nameLabel.TextWrapped = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.fromScale(1, 1 / 3)

    local nameUiStroke = Instance.new("UIStroke")
    nameUiStroke.Name = "nameUiStroke"
    nameUiStroke.Color = Color3.fromRGB(38, 71, 118)
    nameUiStroke.Thickness = 0.5
    nameUiStroke.Transparency = 0.5
    nameUiStroke.Parent = nameLabel

    nameLabel.Parent = holderFrame
    holderFrame.Parent = billboardGui
    --#endregion

    maid:GiveTask(billboardGui)

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    -- Doesn't account for `instance` being rotated - I'm lazy, sorry!
    function nametag:Mount(instance: BasePart | Model)
        if instance:IsA("BasePart") then
            local offset = Vector3.new(0, (instance.Size.Y + billboardGui.Size.Y.Scale) / 2, 0)
            billboardGui.StudsOffset = offset / 2
            billboardGui.StudsOffsetWorldSpace = offset / 2
            billboardGui.Parent = instance
            return
        end

        if instance:IsA("Model") then
            -- ERROR: Needs primary part
            if not instance.PrimaryPart then
                error("Model has no primary part")
            end

            local cframe, size = instance:GetBoundingBox()
            local primaryPartCFrame = instance.PrimaryPart.CFrame
            local offset = Vector3.new(0, (size.Y + billboardGui.Size.Y.Scale) / 2 + (cframe.Position.Y - primaryPartCFrame.Position.Y), 0)

            billboardGui.StudsOffset = offset / 2 -- A mix of both behaviour seemed to work best
            billboardGui.StudsOffsetWorldSpace = offset / 2

            billboardGui.Parent = instance.PrimaryPart
            return
        end

        error(("Bad instance %q"):format(instance.ClassName))
    end

    function nametag:SetName(name: string)
        nameLabel.Text = name
    end

    function nametag:HideFrom(player: Player?)
        billboardGui.PlayerToHideFrom = player
    end

    function nametag:Destroy()
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    --todo

    return nametag
end

return Nametag
