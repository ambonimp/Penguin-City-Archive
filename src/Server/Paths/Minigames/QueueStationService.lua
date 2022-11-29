local QueueStationService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local statusBoardTemplate: SurfaceGui = ReplicatedStorage.Templates.Minigames.QueueStationStatus

function QueueStationService.updateStatus(
    statusBoard: BasePart,
    sessionConfig: MinigameConstants.SessionConfig,
    participants: number,
    countdown: number
)
    local surfaceGui = statusBoard:FindFirstChild(statusBoardTemplate.Name)
    local countdownLabel: TextLabel = surfaceGui.Info.Countdown
    local occupancyLabel: TextLabel = surfaceGui.Info.PlayerCount

    if participants >= sessionConfig.MinParticipants then
        countdownLabel.Text = ("Minigame starts in: %d"):format(countdown)
        occupancyLabel.Text = ("%d/%d"):format(participants, sessionConfig.MaxParticipants)
    else
        countdownLabel.Text = ""
        occupancyLabel.Text = ("%d/%d"):format(participants, sessionConfig.MinParticipants)
    end
end

function QueueStationService.resetStatusBoard(station: Model, sessionConfig: MinigameConstants.SessionConfig): BasePart?
    local statusBoard = station:FindFirstChild("StatusBoard")
    if not statusBoard then
        return
    end

    local surfaceGui = statusBoard:FindFirstChild(statusBoardTemplate.Name)
    if not surfaceGui then
        surfaceGui = statusBoardTemplate:Clone()
    end

    surfaceGui.Info.Countdown.Text = ""
    surfaceGui.Info.Occupancy.Text = "0/" .. if not sessionConfig.Multiplayer then 1 else sessionConfig.MaxParticipants

    return statusBoard
end

return QueueStationService
