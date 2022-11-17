-- Just a nice way to load an unload everything regarding a player in one place
local PlayerService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)

local maidByPlayer: { [Player]: typeof(Maid.new()) } = {}

-- Gives a maid that gets destroyed on the PlayerLeaving event; useful for cleaning up caches!
function PlayerService.getPlayerMaid(player: Player)
    return maidByPlayer[player]
end

function PlayerService.Start()
    -- Avoid circular dependencies
    local DataService = require(Paths.Server.Data.DataService)
    local CharacterService = require(Paths.Server.Characters.CharacterService)
    local ProductService = require(Paths.Server.Products.ProductService)
    local ZoneService = require(Paths.Server.Zones.ZoneService)
    local PlotService = require(Paths.Server.Housing.PlotService)
    local RewardsService = require(Paths.Server.RewardsService)
    local SessionService = require(Paths.Server.SessionService)
    local PetsService = require(Paths.Server.Pets.PetsService)

    local function loadPlayer(player)
        -- RETURN: Already loaded (rare studio bug)
        if maidByPlayer[player] then
            return
        end

        -- Create Maid
        maidByPlayer[player] = Maid.new()

        -- Data
        DataService.loadPlayer(player)

        -- Load routines
        SessionService.loadPlayer(player)
        CharacterService.loadPlayer(player)
        ProductService.loadPlayer(player)
        PlotService.loadPlayer(player)
        ZoneService.loadPlayer(player)
        RewardsService.loadPlayer(player)
        PetsService.loadPlayer(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        -- Unload routines
        PlotService.unloadPlayer(player)
        RewardsService.unloadPlayer(player)
        PetsService.unloadPlayer(player)

        -- Destroy Maid
        maidByPlayer[player]:Destroy()
        maidByPlayer[player] = nil

        -- Unload Data Last
        DataService.unloadPlayer(player)
    end)

    Players.PlayerAdded:Connect(loadPlayer)
    for _, player in pairs(Players:GetPlayers()) do
        loadPlayer(player)
    end
end

return PlayerService
