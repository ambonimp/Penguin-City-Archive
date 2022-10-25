local DataController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Promise = require(Paths.Packages.promise)
local Remotes = require(Paths.Shared.Remotes)
local DataUtil = require(Paths.Shared.Utils.DataUtil)

local bank: DataUtil.Store = {}
DataController.Updated = Signal.new() -- {event: string, newValue: any, eventMeta: table?}

-- We use addresses on client too only bc it's convinient to copy same addresses as client
function DataController.get(address: string)
    local value = DataUtil.getFromAddress(bank, address)
    return value
end

-- Queries server
function DataController.getPlayer(player: Player, address: string): DataUtil.Data
    -- EDGE CASE: Local player!
    if player == Players.LocalPlayer then
        return DataController.get(address)
    end

    return Remotes.invokeServer("GetPlayerData", player, address)
end

-- Queries server. Returns the results at the same index they are in in `addresses`
function DataController.getPlayerMany(player: Player, addresses: { string }): { DataUtil.Data }
    -- EDGE CASE: Local player!
    if player == Players.LocalPlayer then
        local result = {}
        for _, address in pairs(addresses) do
            table.insert(result, DataController.get(address))
        end
        return result
    end

    return Remotes.invokeServer("GetPlayerDataMany", player, addresses)
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
    DataUpdated = function(address: string, newValue: any, event: string?, eventMeta: table?)
        loader:andThen(function() --- Ensures data has loaded before any changes are made, just in case
            DataUtil.setFromAddress(bank, address, newValue)
            if event then
                DataController.Updated:Fire(event, newValue, eventMeta)
            end
        end)
    end,
})

-- No other module is initialized until data is received.
loader:await()

return DataController
