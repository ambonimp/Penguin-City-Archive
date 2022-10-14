local HousingController = {}

local Paths = require(script.Parent)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes = require(Paths.Shared.Remotes)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local HousingScreen = require(Paths.Client.UI.Screens.Housing.HouseEditorScreen)

HousingController.houseCF = nil :: CFrame?
HousingController.currentHouse = nil :: Model?

--Sets the players house CF used to place objects when loading
local function setHouseCFrame()
    if Player:GetAttribute(HousingConstants.HouseType) and Player:GetAttribute(HousingConstants.HouseSpawn) then
        HousingController.houseCF = CFrame.new(Player:GetAttribute(HousingConstants.HouseType))
    end
end

function HousingController.Init()
    setHouseCFrame()

    HousingController.isEditing = false :: boolean
end

function setupPlayerHouse()
    --set house cf if it hasn't been already
    if HousingController.houseCF == nil then
        repeat
            task.wait()
        until Player:GetAttribute(HousingConstants.HouseType) and Player:GetAttribute(HousingConstants.HouseSpawn)

        setHouseCFrame()
    end
    --wait for character to load house
    local Character = Player.Character or Player.CharacterAdded:Wait()
    HousingController.loadPlayerHouse(Player, Character)
    --show edit button, true: has access to edit
    HousingScreen.houseEntered(true)
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
function HousingController.getPlayerPlot(player: Player, folder: Folder)
    for _, plot: Model in folder:GetChildren() do
        if plot:GetAttribute(HousingConstants.PlotOwner) == player.UserId then
            return plot
        end
    end
    return nil
end

--Loads a players house
function HousingController.loadPlayerHouse(player: Player, character: Model)
    local plot = HousingController.getPlayerPlot(player, workspace.Rooms.Start.Houses)
    HousingController.currentHouse = plot:FindFirstChildOfClass("Model")
end

return HousingController
