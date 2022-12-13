local SportsGamesConstants = {}

SportsGamesConstants.SpawnpointOffset = Vector3.new(0, 3, 0)
SportsGamesConstants.PlayerTouchDebounceTime = 0.5
SportsGamesConstants.Tag = {
    SportsEquipment = "SportsEquipment",
}
SportsGamesConstants.Attribute = {
    SportsEquipmentType = "SportsEquipmentType",
}
SportsGamesConstants.SportsEquipmentType = {
    Football = "Football",
    HockeyPuck = "HockeyPuck",
}
SportsGamesConstants.PushEquipmentForceByType = {
    [SportsGamesConstants.SportsEquipmentType.Football] = {
        Vertical = 50,
        Horizontal = 70,
    },
    [SportsGamesConstants.SportsEquipmentType.HockeyPuck] = {
        Vertical = 5,
        Horizontal = 90,
    },
}

return SportsGamesConstants
