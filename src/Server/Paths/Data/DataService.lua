--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use addresses, no way to tell if you want to use a number as an index or a key from the address alone
    - No spaces in keys, use underscores or preferably just camel case instead
]]
local DataService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Signal = require(Paths.Shared.Signal)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local ProfileService = require(Paths.Server.Data.ProfileService)
local Config = require(Paths.Server.Data.Config)

DataService.Profiles = {}
DataService.Updated = Signal.new() -- {event: string, player: Player, newValue: any, eventMeta: table?}

-- Gets
function DataService.get(player: Player, address: string): DataUtil.Data
    local profile = DataService.Profiles[player]

    if profile then
        return DataUtil.getFromAddress(profile.Data, address)
    else
        warn(debug.traceback())
        warn("Attempting to get data after release: \n\t Address:" .. address .. "\n\tPlayer: " .. player.Name)
    end
end

-- Sets
function DataService.set(player: Player, address: string, newValue: any, event: string?, eventMeta: table?) -- sets the value using address
    local profile = DataService.Profiles[player]

    if profile then
        DataUtil.setFromAddress(profile.Data, address, newValue)
        Remotes.fireClient(player, "DataUpdated", address, newValue, event, eventMeta)

        if event then
            DataService.Updated:Fire(event, player, newValue, eventMeta)
        end

        return newValue
    else
        warn("Attempting to set data after release: \n\t Address:" .. address .. "\n\tPlayer: " .. player.Name)
    end
end

-- Mimicks table.insert but for a store aka a dictionary, meaning it accounts for gaps
function DataService.append(player: Player, address: string, newValue: any, event: string?, eventMeta: table?): string
    local length = 0
    for i in DataService.get(player, address) do
        local index = tonumber(i)
        length = math.max(index, length)
    end

    local key = tostring(length + 1)
    DataService.set(player, address .. "." .. key, newValue, event, eventMeta)

    return key
end

-- Increments a value at the address by the incrementAmount. Value defaults to 0, incrementAmount defaults to 1
function DataService.increment(player: Player, address: string, incrementAmount: number?, event: string?, eventMeta: table?): number
    incrementAmount = incrementAmount or 1

    -- ERROR: Not a number
    local currentValue = DataService.get(player, address)
    if currentValue ~= nil and typeof(currentValue) ~= "number" then
        error(("Cannot increment address %s; got non-number value %q"):format(address, tostring(currentValue)))
    end

    return DataService.set(player, address, (currentValue or 0) + incrementAmount, event, eventMeta)
end

-- Multiplies a value at the address by the scalar. No defaults
function DataService.multiply(player: Player, address: string, scalar: number, event: string?, eventMeta: table?): number
    -- ERROR: Not a number
    local currentValue = DataService.get(player, address) :: number
    if currentValue ~= nil and typeof(currentValue) ~= "number" then
        error(("Cannot increment address %s; got non-number value %q"):format(address, tostring(currentValue)))
    end

    return DataService.set(player, address, currentValue * scalar, event, eventMeta)
end

function DataService.wipe(player: Player)
    local profile = DataService.Profiles[player]
    profile.Data = nil

    player:Kick("DATA WIPE " .. player.Name)
end

local function reconcile(data: DataUtil.Store, default: DataUtil.Store)
    for k, v in pairs(default) do
        if not tonumber(k) and data[k] == nil then
            data[k] = v
        elseif not tonumber(k) and typeof(v) == "table" then
            reconcile(data[k], v)
        end
    end
end

function DataService.loadPlayer(player)
    local profile = ProfileService.GetProfileStore(Config.DataKey, Config.getDefaults(player))
        :LoadProfileAsync(tostring(player.UserId), "ForceLoad")

    if profile then
        reconcile(profile.Data, Config.getDefaults(player))
        --profile:Reconcile()

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
        GetPlayerData = function(player: Player, address: string)
            return DataService.get(player, address)
        end,
    })
end

return DataService
