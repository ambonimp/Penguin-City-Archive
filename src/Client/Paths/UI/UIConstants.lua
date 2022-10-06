local UIConstants = {}

UIConstants.States = {
    Nothing = "Nothing",
    Loading = "Loading",
    Vehicles = "Vehicles",
    CharacterEditor = "CharacterEditor",
    PizzaMinigame = "PizzaMinigame",
    HousingEdit = "HousingEdit",
    EditingHouse = "EditingHouse",
    PlotSetting = "PlotSetting",
    PlotChanger = "PlotChanger",
    HouseSelectionUI = "HouseSelectionUI",
    HUD = "HUD",
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
    UIConstants.States.PlotSetting,
    UIConstants.States.HouseSelectionUI,
}

UIConstants.Font = Enum.Font.GothamBold

UIConstants.Colors = {
    Buttons = {
        PlayGreen = Color3.fromRGB(56, 196, 13),
        InstructionsOrange = Color3.fromRGB(214, 145, 15),
        CloseRed = Color3.fromRGB(249, 104, 101),
        PenguinBlue = Color3.fromRGB(186, 218, 253),
        DarkPenguinBlue = Color3.fromRGB(38, 71, 118),
    },
}

return UIConstants
