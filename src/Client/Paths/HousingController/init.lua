local Housing = {}

local Paths = require(script.Parent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes

local PlayerData
local ObjectModule
local HousingScreen: typeof(require(Paths.Client.UI.Screens.HousingScreen))
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))

Housing.houseCF = nil
local assets: Folder
Housing.CurrentHouse = nil

--Sets the players house CF used to place objects when loading
local function SetHouseCFrame()
    if Player:GetAttribute("House") and Player:GetAttribute("HouseSpawn") then
        Housing.houseCF = CFrame.new(Player:GetAttribute("House"))
    end
end

function Housing.Init()
    SetHouseCFrame()

    assets = ReplicatedStorage:WaitForChild("Assets")

    ObjectModule = require(Paths.Shared.HousingObjectData)
    PlayerData = require(Paths.Client.DataController)
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
end

--gets the interior plot of a house of any player
function Housing.GetPlayerPlot(player: Player)
    for _, plot in workspace.Houses:GetChildren() do
        if plot:GetAttribute("Owner") == player.UserId then
            return plot
        end
    end
    return nil
end

--Loads a players house and teleports the localplayer to it
function Housing.LoadPlayerHouse(player: Player, character: Model)
    local plot = Housing.GetPlayerPlot(player)
    local data
    local houseCFrame
    if player == Player then
        houseCFrame = Housing.houseCF
        data = PlayerData.get("Igloo.Placements")
    else
        houseCFrame = CFrame.new(Player:GetAttribute("House"))
        data = Remotes.invokeServer("GetPlayerData", player, "Igloo.Placements")
    end
    --[[
    for itemName, objectData in data do --only load objects that  don't interact on client
        if ObjectModule[itemName].interactable == false then
            local Object = assets.Housing[ObjectModule[itemName].type]:FindFirstChild(itemName)

            if Object then
                Object = Object:Clone()
                Object:PivotTo(
                    houseCFrame
                        * CFrame.new(objectData.Position[1], objectData.Position[2], objectData.Position[3])
                        * CFrame.Angles(
                            math.rad(objectData.Rotation[1]),
                            math.rad(objectData.Rotation[2]),
                            math.rad(objectData.Rotation[3])
                        )
                )

                if player ~= Player then
                    Object.Parent = plot:WaitForChild("Furniture")
                end
            end
        end
    end]]
    --move character to interior of house
    character:PivotTo(CFrame.new(player:GetAttribute("HouseSpawn")) * CFrame.new(0, Player.Character:GetExtentsSize().Y / 2, 0))
    Housing.CurrentHouse = plot:FindFirstChildOfClass("Model")
end

return Housing
