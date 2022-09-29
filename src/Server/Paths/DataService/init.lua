--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use addresses, no way to tell if you want to use a number as an index or a key from the address alone
    - No spaces in keys, use underscores or preferably just camel case instead
]]
local DataService = {}

local Players = game:GetService("Players")
local Paths = require(script.Parent)
local Remotes = require(Paths.Shared.Remotes)
local Signal = require(Paths.Shared.Signal)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local ProfileService = require(script.ProfileService)
local Config = require(script.Config)

DataService.Profiles = {}
DataService.Updated = Signal.new()

-- Gets
function DataService.get(player: Player, address: string): any
    local profile = DataService.Profiles[player]

    if profile then
        return DataUtil.getFromAddress(profile.Data, address)
    else
        warn(debug.traceback())
        warn("Attempting to get data after release: \n\t Address:" .. address .. "\n\tPlayer: " .. player.Name)
    end
end

-- Sets
function DataService.set(player: Player, address: string, newValue: any, event: string?) -- sets the value using address
    local profile = DataService.Profiles[player]

    if profile then
        newValue = DataUtil.setFromAddress(profile.Data, DataUtil.keysFromAddress(address), newValue)
        Remotes.fireClient(player, "DataUpdated", address, newValue, event)

        if event then
            DataService.Updated:Fire(event, player, newValue)
        end

        return newValue
    else
        warn("Attempting to set data after release: \n\t Address:" .. address .. "\n\tPlayer: " .. player.Name)
    end
end

-- Mimicks table.insert but for a store aka a dictionary, meaning it accounts for gaps
function DataService.append(player: Player, address: string, newValue: any, event: string?): string
    local length = 0
    for i in DataService.get(player, address) do
        local index = tonumber(i)
        length = math.max(index, length)
    end

    local key = tostring(length + 1)
    DataService.set(player, address .. "." .. key, newValue, event)

    return key
end

-- Increments a value at the address by the addend. Value defaults to 0, addend defaults to 1
function DataService.increment(player: Player, address: string, addend: number?, event: string?)
    local currentValue = DataService.get(player, address)
    return DataService.set(player, address, (currentValue or 0) + (addend or 1), event)
end

-- Multiplies a value at the address by the multiplicand. No defaults
function DataService.multiply(player: Player, address: string, multiplicand: number, event: string?)
    local currentValue = DataService.get(player, address)
    return DataService.set(player, address, currentValue * multiplicand, event)
end

function DataService.wipe(player: Player)
    local profile = DataService.Profiles[player]
    profile.Data = nil

    player:Kick("DATA WIPE " .. player.Name)
end

function DataService.loadPlayer(player)
    local profile = ProfileService.GetProfileStore(Config.DataKey, Config.getDefaults(player))
        :LoadProfileAsync(tostring(player.UserId), "ForceLoad")

    if profile then
        profile:Reconcile()

        profile:ListenToRelease(function()
            DataService.Profiles[player] = nil
            player:Kick("Data profile released " .. player.Name)
        end)

        if player:IsDescendantOf(Players) then
            DataService.Profiles[player] = profile
            Remotes.fireClient(player, "DataInitialized", profile.Data)
        else
            profile:Release()
        end
    else
        player:Kick("Data profile does not exist " .. player.Name)
    end
end

function DataService.unloadPlayer(player)
    local profile = DataService.Profiles[player]
    if profile then
        -- Data was wiped, reconcile so that stuff unloads properly
        if not profile.Data then
            profile.Data = {}
            profile:Reconcile()
        end

        profile:Release()
    end
end

-- Communication
do
    Remotes.declareEvent("DataUpdated")

    Remotes.bindFunctions({
        GetPlayerData = function(player: Player, path: string)
            return DataService.get(player, path)
        end,
    })
end

return DataService
