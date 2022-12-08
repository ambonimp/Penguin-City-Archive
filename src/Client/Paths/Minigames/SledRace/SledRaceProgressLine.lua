local SledRaceProgressLine = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SledRaceUtil = require(Paths.Shared.Minigames.SledRace.SledRaceUtil)
local SignedDistanceUtil = require(Paths.Shared.Utils.SignedDistanceUtil)
local SledRaceScreen = require(Paths.Client.UI.Screens.Minigames.SledRaceScreen)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

local POSITION_INDICATOR_HEIGHT = 5 -- Pixels

function SledRaceProgressLine.setup()
    local map = MinigameController.getMap()
    local slopeBoundingSize: Vector3, slopeCFrame: CFrame = SledRaceUtil.getSlopeBoundingBox(map)

    local finishingPoint: Vector3 = slopeCFrame:PointToWorldSpace(slopeBoundingSize * Vector3.new(0, -0.5, -0.5))
    local startingPoint: number = slopeCFrame:PointToWorldSpace(slopeBoundingSize * Vector3.new(0, 0.5, 0.5)).Y
    local worldRangeEnd = slopeBoundingSize.Y - map.Slope:FindFirstChildWhichIsA("BasePart").Size.Y

    local positions, uiRangeEnd = SledRaceScreen.openProgressLine(POSITION_INDICATOR_HEIGHT)
    local sleds: { [Player]: BasePart } = {}
    for _, participant in pairs(MinigameController.getParticpants()) do
        sleds[participant] = SledRaceUtil.getSled(participant):WaitForChild("Physics")
    end

    local reposition: RBXScriptConnection = RunService.RenderStepped:Connect(function()
        for participant, sled in pairs(sleds) do
            local closestPointToFinishLine = SignedDistanceUtil.getBoxClosestPoint(sled, finishingPoint)

            local displacement: number = math.max(0, startingPoint - closestPointToFinishLine.Y)
            local progress: number = displacement / worldRangeEnd

            positions[participant].Position =
                UDim2.new(1, 0, 1 - MathUtil.map(progress, 0, 1, 0, uiRangeEnd :: number), -POSITION_INDICATOR_HEIGHT)
        end
    end)

    return function()
        reposition:Disconnect()
        SledRaceScreen.closeProgressLine()
    end
end

return SledRaceProgressLine
