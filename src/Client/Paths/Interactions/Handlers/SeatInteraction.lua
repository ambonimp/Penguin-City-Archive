local SeatInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)

local RESIT_DELAY = 0.05

local player = Players.LocalPlayer

InteractionController.registerInteraction("Seat", function(seat, prompt)
    prompt.Enabled = false

    local humanoid: Humanoid = player.Character.Humanoid
    if humanoid:GetState() == Enum.HumanoidStateType.Seated then
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        task.wait(RESIT_DELAY)
    end

    seat = seat :: Seat
    seat:Sit(humanoid)

    local standingConnection
    standingConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if seat.Occupant ~= humanoid then
            standingConnection:Disconnect()
            prompt.Enabled = true
        end
    end)
end, "Sit")

return SeatInteraction
