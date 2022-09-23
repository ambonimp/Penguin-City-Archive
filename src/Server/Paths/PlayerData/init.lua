--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use paths, no way to tell if you want to use a number as an index or a key from the path alone
    - No spaces in keys, use underscores or preferably just camel case instead
]]
local PlayerData = {}

local Players = game:GetService("Players")
local Paths = require(script.Parent)
local Remotes = require(Paths.Shared.Remotes)
local Signal = require(Paths.Shared.Signal)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local ProfileService = require(script.ProfileService)
local Config = require(script.Config)

PlayerData.Profiles = {}
PlayerData.Updated = Signal.new()

-- Gets
function PlayerData.get(player, path)
    local profile = PlayerData.Profiles[player]

    if profile then
        return DataUtil.getFromPath(profile.Data, path)
    else
        warn(debug.traceback())
        warn("Attempting to get data after release: \n\t Path:" .. path .. "\n\tPlayer: " .. player.Name)
    end
end

-- Sets
function PlayerData.set(player, path, newValue, event) -- sets the value using path
    local profile = PlayerData.Profiles[player]

    if profile then
        newValue = DataUtil.setFromPath(profile.Data, DataUtil.keysFromPath(path), newValue)
        Remotes.fireClient(player, "DataUpdated", path, newValue, event)

        if event then
            PlayerData.Updated:Fire(event, player, newValue)
        end

        return newValue
    else
        warn("Attempting to set data after release: \n\t Path:" .. path .. "\n\tPlayer: " .. player.Name)
    end
end

-- Mimicks table.insert but for a store aka a dictionary, meaning it accounts for gaps
function PlayerData.append(player, path, newValue, event)
    local length = 0
    for i in PlayerData.get(player, path) do
        local index = tonumber(i)
        length = math.max(index, length)
    end

    local key = tostring(length + 1)
    PlayerData.set(player, path .. "." .. key, newValue, event)

    return key
end

-- Increments a value at the path by the addend. Value defaults to 0, addend defaults to 1
function PlayerData.increment(player, path, addend, event)
    local currentValue = PlayerData.get(player, path)
    return PlayerData.set(player, path, (currentValue or 0) + (addend or 1), event)
end

-- Multiplies a value at the path by the multiplicand. No defaults
function PlayerData.multiply(player, path, multiplicand, event)
    local currentValue = PlayerData.get(player, path)
    return PlayerData.set(player, path, currentValue * multiplicand, event)
end

function PlayerData.wipe(player)
    local profile = PlayerData.Profiles[player]
    profile.Data = nil

    player:Kick("DATA WIPE " .. player.Name)
end

function PlayerData.loadPlayer(player)
    local profile = ProfileService.GetProfileStore(Config.DataKey, Config.getDefaults(player))
        :LoadProfileAsync(tostring(player.UserId), "ForceLoad")

    if profile then
        profile:Reconcile()

        profile:ListenToRelease(function()
            PlayerData.Profiles[player] = nil
            player:Kick("Data profile released " .. player.Name)
        end)

        if player:IsDescendantOf(Players) then
            PlayerData.Profiles[player] = profile
            Remotes.fireClient(player, "DataInitialized", profile.Data)
        else
            profile:Release()
        end
    else
        player:Kick("Data profile does not exist " .. player.Name)
    end
end

function PlayerData.unloadPlayer(player)
    local profile = PlayerData.Profiles[player]
    if profile then
        -- Data was wiped, reconcile so that stuff unloads properly
        if not profile.Data then
            profile.Data = {}
            profile:Reconcile()
        end

        profile:Release()
    end
end

return PlayerData
