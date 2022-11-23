local HousingController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

local exteriorPlots = workspace.Rooms.Neighborhood[HousingConstants.ExteriorFolderName]

function HousingController.getPlotFromOwner(owner: Player, type: string)
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

return HousingController
