local HousingController = {}

local Paths = require(script.Parent)

local Players = game:GetService("Players")
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

local player = Players.LocalPlayer
local plots = workspace.Rooms.Neighborhood.HousingPlots

local uiStateMachine = UIController.getStateMachine()
HousingController.CurrentHouse = nil :: Model?

local function setupPlayerHouse()
    --wait for character to load house
    local Character = player.Character or player.CharacterAdded:Wait()
    HousingController.loadPlayerHouse(player, Character)
end

function HousingController.Start()
    -- Enter/Exit
    ZoneController.ZoneChanged:Connect(function(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
        if ZoneUtil.isHouseZone(fromZone) then
            if uiStateMachine:HasState(UIConstants.House) then
                if uiStateMachine:GetState() ~= UIConstants.House then
                    uiStateMachine:PopTo(UIConstants.States.House)
                end

                uiStateMachine:Pop()
            end
        end
        if ZoneUtil.isHouseZone(toZone) then
            local zoneOwner = ZoneUtil.getHouseZoneOwner(toZone)
            local hasEditPerms = zoneOwner == Players.LocalPlayer --TODO Check DataController for list of UserId we have edit perms for

            if zoneOwner == player then
                uiStateMachine:Push(UIConstants.States.House, {
                    CanEdit = true,
                })
            else
                uiStateMachine:Push(UIConstants.States.House, {
                    CanEdit = hasEditPerms,
                })
            end
        end
    end)

    setupPlayerHouse()
end

--gets the plot of a house of any player
function HousingController.getPlayerPlot(player: Player, type: string)
    if type == HousingConstants.PlotType then
        for _, plot: Model in plots:GetChildren() do
            if plot:GetAttribute(HousingConstants.PlotOwner) == player.UserId then
                return plot
            end
        end
    elseif type == HousingConstants.HouseType then
        local houseZone = ZoneUtil.houseZone(player)
        local zoneModel = ZoneUtil.getZoneTypeDirectory(houseZone.ZoneType):WaitForChild(houseZone.ZoneId)
        if zoneModel then
            local model = zoneModel:FindFirstChildOfClass("Model")
            if model then
                return model
            end
        end
    else
        warn(("unknown house type %q"):format(type))
    end

    return nil
end

--Loads a players house
function HousingController.loadPlayerHouse(owner: Player, character: Model)
    local plot = HousingController.getPlayerPlot(owner, HousingConstants.HouseType)
    HousingController.CurrentHouse = plot:FindFirstChildOfClass("Model")
end

return HousingController
