local HousingController = {}

local Paths = require(script.Parent)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes = require(Paths.Shared.Remotes)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))
local PlotChanger: typeof(require(Paths.Client.HousingController.PlotChanger))

local plots = workspace.Rooms.Neighborhood.HousingPlots

HousingController.currentHouse = nil :: Model?

function HousingController.Init()
    HousingController.isEditing = false :: boolean
end

local function setupPlayerHouse()
    --wait for character to load house
    local Character = Player.Character or Player.CharacterAdded:Wait()
    HousingController.loadPlayerHouse(Player, Character)

    --show edit button, true: has access to edit
    HousingScreen.houseEntered(true)
    EditMode = require(Paths.Client.HousingController.EditMode)
    PlotChanger = require(Paths.Client.HousingController.PlotChanger)
end

function HousingController.Start()
    Remotes.bindEvents({
        EnteredHouse = function(player: Player, hasAccess: boolean)
            if player == Player then
                HousingScreen.houseEntered(true)
            else
                HousingScreen.houseEntered(hasAccess)
            end
        end,
        ExitedHouse = function(player: Player)
            HousingScreen.houseExited(false)
        end,
        PlotChanged = function(newPlot: Model)
            HousingScreen.plotChanged(newPlot)
        end,
    })
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
        local zoneModel = game.Workspace.Rooms:FindFirstChild(tostring(player.UserId))
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
function HousingController.loadPlayerHouse(player: Player, character: Model)
    local plot = HousingController.getPlayerPlot(player, HousingConstants.HouseType)
    HousingController.currentHouse = plot:FindFirstChildOfClass("Model")
end

return HousingController
