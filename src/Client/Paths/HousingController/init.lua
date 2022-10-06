local Housing = {}

local Paths = require(script.Parent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes

local HousingScreen: typeof(require(Paths.Client.UI.Screens.HousingScreen))
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))
local PlotChanger: typeof(require(Paths.Client.HousingController.PlotChanger))

Housing.houseCF = nil
Housing.CurrentHouse = nil

--Sets the players house CF used to place objects when loading
local function SetHouseCFrame()
    if Player:GetAttribute("House") and Player:GetAttribute("HouseSpawn") then
        Housing.houseCF = CFrame.new(Player:GetAttribute("House"))
    end
end

function Housing.Init()
    SetHouseCFrame()

    Remotes = require(Paths.Shared.Remotes)
    HousingScreen = require(Paths.Client.UI.Screens.HousingScreen)
    Housing.isEditing = false
end

function Housing.Start()
    Remotes.bindEvents({
        EnteredHouse = function(player: Player, hasAccess: boolean)
            if player == Player then
                HousingScreen.HouseEntered(true)
            else
                HousingScreen.HouseEntered(hasAccess)
            end
        end,
        ExitedHouse = function(player: Player)
            HousingScreen.HouseExited(false)
        end,
        PlotChanged = function(newPlot: Model)
            HousingScreen.PlotChanged(newPlot)
        end,
    })
    --set house cf if it hasn't been already
    if Housing.houseCF == nil then
        repeat
            task.wait()
        until Player:GetAttribute("House") and Player:GetAttribute("HouseSpawn")

        SetHouseCFrame()
    end
    --wait for character to load house
    local Character = Player.Character or Player.CharacterAdded:Wait()
    Housing.LoadPlayerHouse(Player, Character)
    --show edit button, true: has access to edit
    HousingScreen.HouseEntered(true)
    EditMode = require(Paths.Client.HousingController.EditMode)
    PlotChanger = require(Paths.Client.HousingController.PlotChanger)
end

--gets the plot of a house of any player
function Housing.GetPlayerPlot(player: Player, folder: Folder): Model | nil
    for _, plot in folder:GetChildren() do
        if plot:GetAttribute("Owner") == player.UserId then
            return plot
        end
    end
    return nil
end

--Loads a players house and teleports the localplayer to it
function Housing.LoadPlayerHouse(player: Player, character: Model)
    local plot = Housing.GetPlayerPlot(player, workspace.Houses)
    --move character to interior of house
    character:PivotTo(CFrame.new(player:GetAttribute("HouseSpawn")) * CFrame.new(0, Player.Character:GetExtentsSize().Y / 2, 0))
    Housing.CurrentHouse = plot:FindFirstChildOfClass("Model")
end

return Housing
