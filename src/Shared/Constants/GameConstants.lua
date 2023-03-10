local GameConstants = {}

GameConstants.BranchName = nil :: string | nil -- Feel free to place the name of your branch here for more specific versioning
GameConstants.Version = "v0.0.0"
GameConstants.GameName = "penguin-city"
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
    Dev = 32,
    QA = 4,
    Live = 1, --!! Dangerous. Past nums: (1: Alpha)
}

return GameConstants
