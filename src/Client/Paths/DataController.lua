local DataController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Promise = require(Paths.Packages.promise)
local Remotes = require(Paths.Shared.Remotes)
local DataUtil = require(Paths.Shared.Utils.DataUtil)

local bank = {}
DataController.Updated = Signal.new()

-- We use paths on client too only bc it's convinient to copy same paths as client
function DataController.get(path)
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
                DataController.Updated:Fire(event, newValue)
            end
        end)
    end,
})

-- No other module is initialized until data is received.
loader:await()

return DataController
