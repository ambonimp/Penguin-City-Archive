--[[
    Keeps our `Sessions` populated with beaucoup de information; used for our "Session Summary" telemetry
]]
local SessionService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Session = require(Paths.Shared.Session)
local PlayerService = require(Paths.Server.PlayerService)
local DataService = require(Paths.Server.Data.DataService)

local DATA_ADDRESS_TOTAL_PLAY_SESSIONS = "Sessions.TotalSessions"

local sessionByPlayer: { [Player]: typeof(Session.new(game.Players:GetPlayers()[1])) } = {}
local loadCallbacks: { (player: Player) -> any } = {}

function SessionService.Start()
    -- Dependencies only needed in this scope
    local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
    local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
    local ZoneService = require(Paths.Server.Zones.ZoneService)
    local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
    local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
    local ProductUtil = require(Paths.Shared.Products.ProductUtil)
    local ProductService = require(Paths.Server.Products.ProductService)
    local Products = require(Paths.Shared.Products.Products)

    -- Populate minigame time sessions
    do
        MinigameSession.MinigameFinished:Connect(
            function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
                local minigameTimeSeconds = minigameSession:GetSessionTime()
                for _, scoreInfo in pairs(sortedScores) do
                    local session = SessionService.getSession(scoreInfo.Player)
                    if session then
                        session:AddMinigameTimeSeconds(minigameTimeSeconds)
                    end
                end
            end
        )
    end

    -- Populate ZoneTeleports
    do
        ZoneService.ZoneChanged:Connect(
            function(player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
                local session = SessionService.getSession(player)
                if session then
                    session:ReportZoneTeleport(fromZone, toZone, teleportData)
                end
            end
        )
    end

    -- Product Purchasing
    do
        ProductService.ProductAdded:Connect(function(player: Player, product: Products.Product, amount: number)
            local session = SessionService.getSession(player)
            if session then
                local amountOwnedBefore = ProductService.getProductCount(player, product) - amount
                local isFreshlyOwned = amountOwnedBefore == 0

                if isFreshlyOwned then
                    session:ProductPurchased(product)
                end
            end
        end)
    end

    -- Product Equipping
    do
        -- Clothing
        do
            CharacterItemService.ItemEquipped:Connect(function(player: Player, categoryName: string, itemName: string)
                local session = SessionService.getSession(player)
                local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
                if session and product then
                    session:ProductEquipped(product)
                end
            end)
            CharacterItemService.ItemUnequipped:Connect(function(player: Player, categoryName: string, itemName: string)
                local session = SessionService.getSession(player)
                local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
                if session and product then
                    session:ProductUnequipped(product)
                end
            end)
            SessionService.addLoadCallback(function(player: Player)
                local session = SessionService.getSession(player)
                if session then
                    local equippedItems = CharacterItemService.getEquippedCharacterItems(player)
                    for categoryName, itemNames in pairs(equippedItems) do
                        for _, itemName in pairs(itemNames) do
                            local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
                            if product then
                                session:ProductEquipped(product)
                            end
                        end
                    end
                end
            end)
        end

        -- Pets
        do
        end
    end
end

function SessionService.loadPlayer(player: Player)
    -- Load `Session` Object
    sessionByPlayer[player] = Session.new(player)
    PlayerService.getPlayerMaid(player):GiveTask(function()
        sessionByPlayer[player] = nil
    end)

    -- Add to total play sessions
    DataService.increment(player, DATA_ADDRESS_TOTAL_PLAY_SESSIONS, 1)

    -- Callbacks
    for _, callback in pairs(loadCallbacks) do
        callback(player)
    end
end

function SessionService.addLoadCallback(callback: (player: Player) -> any)
    table.insert(loadCallbacks, callback)
end

function SessionService.getSession(player: Player)
    return sessionByPlayer[player]
end

function SessionService.getTotalPlaySessions(player: Player): number
    return DataService.get(player, DATA_ADDRESS_TOTAL_PLAY_SESSIONS) or 0
end

return SessionService
