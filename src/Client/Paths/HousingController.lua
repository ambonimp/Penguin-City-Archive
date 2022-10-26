local HousingController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

local uiStateMachine = UIController.getStateMachine()
local exteriorPlots = workspace.Rooms.Neighborhood[HousingConstants.ExteriorFolderName]

local function getPlotFromOwner(owner: Player, type: string)
    if type == HousingConstants.ExteriorType then
        for _, plot: Model in exteriorPlots:GetChildren() do
            if plot:GetAttribute(HousingConstants.PlotOwner) == owner.UserId then
                return plot
            end
        end
    elseif type == HousingConstants.InteriorType then
        local houseInteriorZone = ZoneUtil.houseInteriorZone(owner)
        local plot = ZoneUtil.getZoneTypeDirectory(houseInteriorZone.ZoneType):WaitForChild(houseInteriorZone.ZoneId)
        if plot then
            return plot.InteriorPlot
        end
    else
        warn(("unknown house type %q"):format(type))
    end

    return nil
end

function HousingController.Start()
    -- Enter/Exit
    ZoneController.ZoneChanged:Connect(function(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
        if ZoneUtil.isHouseInteriorZone(fromZone) then
            uiStateMachine:Remove(UIConstants.States.House)
        end
        if ZoneUtil.isHouseInteriorZone(toZone) then
            local zoneOwner = ZoneUtil.getHouseInteriorZoneOwner(toZone)
            local hasEditPerms = ZoneController.hasEditPerms(zoneOwner)

            uiStateMachine:Push(UIConstants.States.House, {
                CanEdit = hasEditPerms,
                InteriorPlot = getPlotFromOwner(zoneOwner, HousingConstants.InteriorType),
            })
        end
    end)
end

return HousingController
