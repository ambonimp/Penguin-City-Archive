local Housing = {}

local Paths = require(script.Parent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes

local PlayerData
local ObjectModule

local houseCF: CFrame
local assets: Folder

local isEditing: boolean

local function SetHouseCFrame()
    if Player:GetAttribute("House") and Player:GetAttribute("HouseSpawn") then
        houseCF = CFrame.new(Player:GetAttribute("House")) * CFrame.Angles(0, math.rad(180), 0)
    end
end

function Housing.Init()
    SetHouseCFrame()

    assets = ReplicatedStorage:WaitForChild("Assets")

    ObjectModule = require(Paths.Shared.HousingObjectData)
    PlayerData = require(Paths.Client.DataController)
    Remotes = require(Paths.Shared.Remotes)
    isEditing = false
end

function Housing.Start()
    if houseCF == nil then
        repeat
            task.wait()
        until Player:GetAttribute("House") and Player:GetAttribute("HouseSpawn")

        SetHouseCFrame()
    end
    local Character = Player.Character or Player.CharacterAdded:Wait()
    Housing.LoadPlayerHouse(Player, Character)
end

--Loads a players house and teleports the localplayer to it
function Housing.LoadPlayerHouse(player: Player, character: Model)
    local data
    local houseCFrame
    if player == Player then
        houseCFrame = houseCF
        data = PlayerData.get("Igloo.Placements")
    else
        houseCFrame = CFrame.new(Player:GetAttribute("House")) * CFrame.Angles(0, math.rad(180), 0)
        data = Remotes.invokeServer("GetPlayerData", player, "Igloo.Placements")
    end

    for itemName, objectData in data do --only load objects that  don't interact on client
        if ObjectModule[itemName].interactable == false then
            local Object = assets.Housing[ObjectModule[itemName].type]:FindFirstChild(itemName)

            if Object then
                Object = Object:Clone()
                Object:SetPrimaryPartCFrame(
                    houseCFrame
                        * CFrame.new(objectData.Position[1], objectData.Position[2], objectData.Position[3])
                        * CFrame.Angles(
                            math.rad(objectData.Rotation[1]),
                            math.rad(objectData.Rotation[2]),
                            math.rad(objectData.Rotation[3])
                        )
                )
                Object.Parent = workspace.LoadedHouse
            end
        end
    end

    character:PivotTo(CFrame.new(player:GetAttribute("HouseSpawn")) * CFrame.new(0, Player.Character:GetExtentsSize().Y / 2, 0))
end

return Housing
