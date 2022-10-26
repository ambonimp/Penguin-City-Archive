local GameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

type PlaceName = "Dev" | "Live" | "QA" | "feature"

function GameUtil.getPlaceId()
    return game.PlaceId
end

function GameUtil.getGameId()
    return game.GameId
end

function GameUtil.isLiveGame()
    return GameUtil.getGameId() == GameConstants.GameId.Live
end

function GameUtil.isQAGame()
    return GameUtil.getGameId() == GameConstants.GameId.QA
end

function GameUtil.isDevGame()
    return GameUtil.getGameId() == GameConstants.GameId.Dev
end

function GameUtil.isBranchGame()
    return not (GameUtil.isLiveGame() or GameUtil.isQAGame() or GameUtil.isDevGame())
end

function GameUtil.getPlaceName(): PlaceName
    return GameUtil.isLiveGame() and "Live"
        or GameUtil.isDevGame() and "Dev"
        or GameUtil.isQAGame() and "QA"
        or GameUtil.isBranchGame() and GameConstants.BranchName
        or "feature/?"
end

function GameUtil.getDataKey()
    local num = GameConstants.DataIds[GameUtil.getPlaceName()] or GameConstants.DataIds.Dev
    return ("%s_%d"):format(GameUtil.getPlaceName(), num)
end

return GameUtil
