local UIConstants = {}

UIConstants.States = {
    Nothing = "Nothing",
    Loading = "Loading",
    Vehicles = "Vehicles",
    PizzaMinigame = "PizzaMinigame",
}

UIConstants.Keybinds = {
    PopStateMachine = {
        Enum.KeyCode.ButtonB,
        Enum.KeyCode.B,
    },
}

UIConstants.DontPopStatesFromKeybind = {
    UIConstants.States.Nothing,
    UIConstants.States.Loading,
}

UIConstants.Font = Enum.Font.GothamBold

UIConstants.Colors = {
    Buttons = {
        PlayGreen = Color3.fromRGB(56, 196, 13),
        InstructionsOrange = Color3.fromRGB(214, 145, 15),
    },
}

return UIConstants
