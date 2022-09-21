local PlayerData = {}

local Paths = require(script.Parent)

local modules = Paths.Modules
local Signal = modules.Signal
local Promise = modules.Promise
local Remotes = modules.Remotes
local DataUtil = modules.DataUtil

local bank = {}
PlayerData.Updated = Signal.new()

-- We use paths on client too only bc it's convinient to copy same paths as client
function PlayerData.get(path)
    return DataUtil.getFromPath(bank, path)
end

local loader = Promise.new(function(resolve)
    Remotes.bindEvents({
        DataInitialized = function(data)
            bank = data
            resolve()
        end,
    })
end)

Remotes.bindEvents({
    DataUpdated = function(path, newValue, event)
        loader:andThen(function() --- Ensures data has loaded before any changes are made, just in case
            DataUtil.setFromPath(bank, DataUtil.keysFromPath(path), newValue)
            if event then
                PlayerData.Updated:Fire(event, newValue)
            end
        end)
    end,
})

-- No other PlayerData is initialized until data is received.
loader:await()

return PlayerData
