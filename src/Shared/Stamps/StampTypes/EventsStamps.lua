local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

return {
    {
        Id = "events_alpha",
        DisplayName = "Alpha Tester",
        Description = ("Play %s in Alpha"):format(GameConstants.PrettyGameName),
        Type = "Events",
        Difficulty = "???",
        ImageId = "",
    },
}
