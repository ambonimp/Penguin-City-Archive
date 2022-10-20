local UIConstants = {}

UIConstants.States = {
    Nothing = "Nothing",
    Loading = "Loading",
    Vehicles = "Vehicles",
    CharacterEditor = "CharacterEditor",
    PizzaMinigame = "PizzaMinigame",
    House = "House",
    HouseEditor = "HouseEditor",
    PlotSettings = "PlotSettings",
    PlotChanger = "PlotChanger",
    HouseSelectionUI = "HouseSelectionUI",
    HUD = "HUD",
    Results = "Results",
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

UIConstants.AllowHUDWith = {
    UIConstants.States.Vehicles,
    UIConstants.States.PlotSettingss,
    UIConstants.States.PlotChanger,
    UIConstants.States.HouseSelectionUI,
}

UIConstants.EnableCoreGuiInStates = {
    UIConstants.States.Nothing,
    UIConstants.States.Loading,
    UIConstants.States.HUD,
    UIConstants.States.Vehicles,
}

UIConstants.Font = Enum.Font.GothamBold

UIConstants.Colors = {
    Misc = {
        White = Color3.fromRGB(255, 255, 255),
    },
    Buttons = {
        PlayGreen = Color3.fromRGB(56, 196, 13),
        InstructionsOrange = Color3.fromRGB(214, 145, 15),
        CloseRed = Color3.fromRGB(249, 104, 101),
        PenguinBlue = Color3.fromRGB(186, 218, 253),
        DarkPenguinBlue = Color3.fromRGB(38, 71, 118),
        NextGreen = Color3.fromRGB(43, 195, 114),
    },
}

UIConstants.Offsets = {
    ButtonOutlineThickness = 4,
}

UIConstants.DefaultButtonDebounce = 0.2

return UIConstants
