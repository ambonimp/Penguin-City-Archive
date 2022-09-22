local UIConstants = {}

UIConstants.States = {
    Nothing = "Nothing",
    Vehicles = "Vehicles",
}

UIConstants.Keybinds = {
    PopStateMachine = {
        Enum.KeyCode.ButtonB,
        Enum.KeyCode.B,
    },
}

UIConstants.DontPopStatesFromKeybind = {
    UIConstants.States.Nothing,
}

UIConstants.Font = Enum.Font.GothamBold

return UIConstants
