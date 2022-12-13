local SportsGamesConstants = {}

SportsGamesConstants.SpawnpointOffset = Vector3.new(0, 3, 0)
SportsGamesConstants.PlayerTouchDebounceTime = 0.5
SportsGamesConstants.PushEquipmentForce = {
    Vertical = 50,
    Horizontal = 70,
}
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

return SportsGamesConstants
