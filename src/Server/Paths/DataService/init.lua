--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use paths, no way to tell if you want to use a number as an index or a key from the path alone
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
function DataService.get(player: Player, path: string): any
    local profile = DataService.Profiles[player]

    if profile then
        return DataUtil.getFromPath(profile.Data, path)
    else
        warn(debug.traceback())
        warn("Attempting to get data after release: \n\t Path:" .. path .. "\n\tPlayer: " .. player.Name)
    end
end

-- Sets
function DataService.set(player: Player, path: string, newValue: any, event: string?) -- sets the value using path
    local profile = DataService.Profiles[player]

    if profile then
        newValue = DataUtil.setFromPath(profile.Data, DataUtil.keysFromPath(path), newValue)
        Remotes.fireClient(player, "DataUpdated", path, newValue, event)

        if event then
            DataService.Updated:Fire(event, player, newValue)
        end

        return newValue
    else
        warn("Attempting to set data after release: \n\t Path:" .. path .. "\n\tPlayer: " .. player.Name)
    end
end

-- Mimicks table.insert but for a store aka a dictionary, meaning it accounts for gaps
function DataService.append(player: Player, path: string, newValue: any, event: string?): string
    local length = 0
    for i in DataService.get(player, path) do
        local index = tonumber(i)
        length = math.max(index, length)
    end

    local key = tostring(length + 1)
    DataService.set(player, path .. "." .. key, newValue, event)

    return key
end

-- Increments a value at the path by the addend. Value defaults to 0, addend defaults to 1
function DataService.increment(player: Player, path: string, addend: number?, event: string?)
    local currentValue = DataService.get(player, path)
    return DataService.set(player, path, (currentValue or 0) + (addend or 1), event)
end

-- Multiplies a value at the path by the multiplicand. No defaults
function DataService.multiply(player: Player, path: string, multiplicand: number, event: string?)
    local currentValue = DataService.get(player, path)
    return DataService.set(player, path, currentValue * multiplicand, event)
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
end

return DataService
