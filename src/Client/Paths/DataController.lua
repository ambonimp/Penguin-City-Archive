local DataController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Promise = require(Paths.Packages.promise)
local Remotes = require(Paths.Shared.Remotes)
local DataUtil = require(Paths.Shared.Utils.DataUtil)

local bank: DataUtil.Store = {}
DataController.Updated = Signal.new()

-- We use addresses on client too only bc it's convinient to copy same addresses as client
function DataController.get(address: string)
    return DataUtil.getFromAddress(bank, address)
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
            DataUtil.setFromAddress(bank, DataUtil.keysFromAddress(path), newValue)
            if event then
                DataController.Updated:Fire(event, newValue)
            end
        end)
    end,
})

-- No other module is initialized until data is received.
loader:await()

return DataController
