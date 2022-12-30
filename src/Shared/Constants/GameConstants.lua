local GameConstants = {}

GameConstants.BranchName = nil :: string | nil -- Feel free to place the name of your branch here for more specific versioning
GameConstants.Version = "v1.0.6"
GameConstants.DataCleanupVersion = 1
GameConstants.GameName = "penguin-city" --!! Used in our Telemetry Scope
GameConstants.PrettyGameName = "Penguin City"

GameConstants.PlaceId = {
    Live = 11173876995,
    QA = 9118461324,
    Dev = 10787436070,
}
GameConstants.GameId = {
    Live = 3992926863,
    QA = 3425594443,
    Dev = 3899496745,
}

GameConstants.DataIds = {
    Dev = 56,
    QA = 8,
    Live = 2, --!! Dangerous. Past nums: (1: Alpha)
}

return GameConstants
