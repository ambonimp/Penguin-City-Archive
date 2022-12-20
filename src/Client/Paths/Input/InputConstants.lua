local InputConstants = {}

InputConstants.Cursor = {
    Down = {
        UserInputTypes = {
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch,
        },
        KeyCodes = {
            Enum.KeyCode.ButtonR2,
        },
    },
    Up = {
        UserInputTypes = {
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch,
        },
        KeyCodes = {
            Enum.KeyCode.ButtonR2,
        },
    },
}

InputConstants.Sprint = {
    KeyCodes = {
        Enum.KeyCode.ButtonL2,
        Enum.KeyCode.LeftControl,
    },
}

InputConstants.KeyCodeNumbers = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7,
    [Enum.KeyCode.Eight] = 8,
    [Enum.KeyCode.Nine] = 9,
}

return InputConstants
