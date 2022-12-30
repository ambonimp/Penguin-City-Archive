-- Just a nice way to load an unload everything regarding a player in one place
local PlayerService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Shared.Maid)
local GroupUtil = require(Paths.Shared.Utils.GroupUtil)
local PlayerConstants = require(Paths.Shared.Constants.PlayerConstants)
local Promise = require(Paths.Packages.promise)

local maidByPlayer: { [Player]: Maid.Maid } = {}
local loadedPlayers = {}

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
    local PetService = require(Paths.Server.Pets.PetService)
    local PlayerChatService = require(Paths.Server.PlayerChatService)
    local ToolService = require(Paths.Server.Tools.ToolService)
    local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
    local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)

    local function loadPlayer(player)
        -- RETURN: Already loaded (rare studio bug)
        if maidByPlayer[player] then
            return
        end

        loadedPlayers[player] = Promise.new(function(resolve)
            -- Create Maid
            maidByPlayer[player] = Maid.new()

            -- Data
            DataService.loadPlayer(player)
            CharacterItemService.loadPlayer(player)

            -- Load routines
            CharacterService.loadPlayer(player)
            ProductService.loadPlayer(player)
            PlotService.loadPlayer(player)
            SessionService.loadPlayer(player) -- SessionService relies on the above Services, they must clean up data first
            ZoneService.loadPlayer(player)
            RewardsService.loadPlayer(player)
            PetService.loadPlayer(player)
            PlayerChatService.loadPlayer(player)
            ToolService.loadPlayer(player)
            TelemetryService.loadPlayer(player)

            resolve()
        end)
    end

    Players.PlayerRemoving:Connect(function(player)
        loadedPlayers[player]:finally(function()
            -- Unload routines
            PlotService.unloadPlayer(player)
            RewardsService.unloadPlayer(player)
            PetService.unloadPlayer(player)
            TelemetryService.unloadPlayer(player)

            -- Destroy Maid
            maidByPlayer[player]:Destroy()
            maidByPlayer[player] = nil

            -- Unload Data Last
            DataService.unloadPlayer(player)

            loadedPlayers[player] = nil
        end)
    end)

    Players.PlayerAdded:Connect(loadPlayer)
    for _, player in pairs(Players:GetPlayers()) do
        loadPlayer(player)
    end
end

function PlayerService.getAestheticRoleDetails(player: Player)
    if GroupUtil.isAdmin(player) then
        return PlayerConstants.AestheticRoleDetails.Admin
    end

    if GroupUtil.isTester(player) then
        return PlayerConstants.AestheticRoleDetails.Tester
    end

    return nil
end

return PlayerService
