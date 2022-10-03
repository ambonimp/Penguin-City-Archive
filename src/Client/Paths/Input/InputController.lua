local InputController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local InputConstants = require(Paths.Client.Input.InputConstants)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)

-- Generic Events that are compatible across PC/Mobile/XBox
InputController.CursorDown = Signal.new()
InputController.CursorUp = Signal.new()

-- Listen to Input
do
    UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: gameProcessedEvent  (minus mobile, finicky!)
        if gameProcessedEvent and inputObject.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- Cursor
        local isCursorDownInput = table.find(InputConstants.Cursor.Down.KeyCodes, inputObject.KeyCode)
            or table.find(InputConstants.Cursor.Down.UserInputTypes, inputObject.UserInputType) and true
            or false
        if isCursorDownInput then
            -- Wait a frame on mobile; needs a frame to update the MouseLocation in UserInputService. This helps fix edge case bugs on this event
            if DeviceUtil.isMobile() then
                task.wait()
            end

            InputController.CursorDown:Fire()
        end
    end)
    UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: gameProcessedEvent (minus mobile, finicky!)
        if gameProcessedEvent and inputObject.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- Cursor
        local isCursorUpInput = table.find(InputConstants.Cursor.Up.KeyCodes, inputObject.KeyCode)
            or table.find(InputConstants.Cursor.Up.UserInputTypes, inputObject.UserInputType) and true
            or false
        if isCursorUpInput then
            InputController.CursorUp:Fire()
        end
    end)
end

return InputController
