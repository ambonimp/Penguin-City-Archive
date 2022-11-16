local UIConstants = {}

UIConstants.States = {
    Loading = "Loading",
    CharacterEditor = "CharacterEditor",
    PizzaMinigame = "PizzaMinigame",
    House = "House",
    HouseEditor = "HouseEditor",
    FurniturePlacement = "FurniturePlacement",
    PlotSettings = "PlotSettings",
    PlotChanger = "PlotChanger",
    HouseSelectionUI = "HouseSelectionUI",
    HUD = "HUD",
    Results = "Results",
    PromptProduct = "PromptProduct",
    StampBook = "StampBook",
    DailyRewards = "DailyRewards",
    GiftPopup = "GiftPopup",
    Paycheck = "Paycheck",
    Inventory = "Inventory",
    GenericPrompt = "GenericPrompt",
    PetEditor = "PetEditor",
}

-- If `key` is in the stack, but `value` is on the top, we will still treat as `key` being at the top of the stack (see UIUtil.getPseudoState)
UIConstants.PseudoStates = {
    [UIConstants.States.HUD] = {
        UIConstants.States.PlotSettings,
        UIConstants.States.PlotChanger,
        UIConstants.States.HouseSelectionUI,
        UIConstants.States.House,
        UIConstants.States.Paycheck,
    },
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

UIConstants.EnableCoreGuiInStates = {
    UIConstants.States.Nothing,
    UIConstants.States.Loading,
    UIConstants.States.HUD,
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
        AvailableGreen = Color3.fromRGB(43, 195, 114),
        UnavailableGrey = Color3.fromRGB(158, 158, 158),
        StampBeige = Color3.fromRGB(225, 209, 159),
        IglooPink = Color3.fromRGB(229, 142, 237),
        WaitOrange = Color3.fromRGB(255, 151, 32),
        EditOrange = Color3.fromRGB(255, 158, 46),
    },
}

UIConstants.Offsets = {
    ButtonOutlineThickness = 4,
}

UIConstants.DefaultButtonDebounce = 0.2

return UIConstants
