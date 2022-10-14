local HousingController = {}

local Paths = require(script.Parent)

local Players = game:GetService("Players")
local Remotes = require(Paths.Shared.Remotes)
local HousingConstants = require(Paths.Shared.Constants.HousingConstants)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)

local player = Players.LocalPlayer
local uiStateMachine = UIController.getStateMachine()

HousingController.HouseCF = nil :: CFrame?
HousingController.CurrentHouse = nil :: Model?

--Sets the players house CF used to place objects when loading
local function setHouseCFrame()
    if player:GetAttribute(HousingConstants.HouseType) and player:GetAttribute(HousingConstants.HouseSpawn) then
        HousingController.HouseCF = CFrame.new(player:GetAttribute(HousingConstants.HouseType))
    end
end

function HousingController.Init()
    setHouseCFrame()
end

function setupPlayerHouse()
    --set house cf if it hasn't been already
    if HousingController.HouseCF == nil then
        repeat
            task.wait()
        until player:GetAttribute(HousingConstants.HouseType) and player:GetAttribute(HousingConstants.HouseSpawn)

        setHouseCFrame()
    end

    --wait for character to load house
    local character = player.Character or player.CharacterAdded:Wait()
    HousingController.loadPlayerHouse(player, character)

    --show edit button, true: has access to edit
    uiStateMachine:Push(UIConstants.States.House, {
        CanEdit = true,
    })
end

function HousingController.Start()
    Remotes.bindEvents({
        EnteredHouse = function(owner: Player, hasAccess: boolean)
            if owner == player then
                uiStateMachine:Push(UIConstants.States.House, {
                    CanEdit = true,
                })
            else
                uiStateMachine:Push(UIConstants.States.House, {
                    CanEdit = hasAccess,
                })
            end
        end,

        ExitedHouse = function()
            if uiStateMachine:GetState() ~= UIConstants.States.House then
                uiStateMachine:PopTo(UIConstants.States.House)
            end

            uiStateMachine:Pop()
        end,
    })
    setupPlayerHouse()
end

--gets the plot of a house of any player
function HousingController.getPlayerPlot(owner: Player, folder: Folder)
    for _, plot: Model in folder:GetChildren() do
        if plot:GetAttribute(HousingConstants.PlotOwner) == owner.UserId then
            return plot
        end
    end
    return nil
end

--Loads a players house
function HousingController.loadPlayerHouse(owner: Player, character: Model)
    local plot = HousingController.getPlayerPlot(owner, workspace.Rooms.Start.Houses)
    HousingController.CurrentHouse = plot:FindFirstChildOfClass("Model")
end

return HousingController
