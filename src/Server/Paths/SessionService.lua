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
    local PetService = require(Paths.Server.Pets.PetService)
    local ToolService = require(Paths.Server.Tools.ToolService)
    local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
    local PlotService = require(Paths.Server.Housing.PlotService)
    local StampService = require(Paths.Server.Stamps.StampService)
    local Stamps = require(Paths.Shared.Stamps.Stamps)

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

    -- Stamp Acquiring
    do
        StampService.StampAdded:Connect(function(player: Player, stamp: Stamps.Stamp, stampTier: Stamps.StampTier | nil)
            local session = SessionService.getSession(player)
            if session then
                session:StampAcquired(stamp, stampTier)
            end
        end)
    end

    -- Product Acquiring
    do
        ProductService.ProductAdded:Connect(function(player: Player, product: Products.Product, amount: number)
            local session = SessionService.getSession(player)
            if session then
                local amountOwnedBefore = ProductService.getProductCount(player, product) - amount
                local isFreshlyOwned = amountOwnedBefore == 0

                if isFreshlyOwned then
                    session:ProductAcquired(product)
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
            PetService.PetEquipped:Connect(function(player: Player, petDataIndex: string)
                local session = SessionService.getSession(player)
                local petData = PetService.getPet(player, petDataIndex)
                if session and petData then
                    warn("todo pet equipped")
                    --session:PetEquipped(petData)
                end
            end)
            PetService.PetUnequipped:Connect(function(player: Player, petDataIndex: string)
                local session = SessionService.getSession(player)
                local petData = PetService.getPet(player, petDataIndex)
                if session and petData then
                    warn("todo pet unequipped")
                    --session:PetUnequipped(petData)
                end
            end)
            SessionService.addLoadCallback(function(player: Player)
                local session = SessionService.getSession(player)
                local petDataIndex = PetService.getEquippedPetDataIndex(player)
                local petData = petDataIndex and PetService.getPet(player, petDataIndex)
                if session and petData then
                    warn("todo pet equipped")
                    --session:PetEquipped(petData)
                end
            end)
        end

        -- Tools
        do
            ToolService.ToolEquipped:Connect(function(player: Player, tool: ToolUtil.Tool)
                local session = SessionService.getSession(player)
                local product = ProductUtil.getToolProduct(tool.CategoryName, tool.ToolId)
                if session and product then
                    session:ProductEquipped(product)
                end
            end)
            ToolService.ToolUnequipped:Connect(function(player: Player, tool: ToolUtil.Tool)
                local session = SessionService.getSession(player)
                local product = ProductUtil.getToolProduct(tool.CategoryName, tool.ToolId)
                if session and product then
                    session:ProductEquipped(product)
                end
            end)
        end

        -- Housing
        do
            PlotService.ObjectPlaced:Connect(function(player: Player, product: Products.Product)
                local session = SessionService.getSession(player)
                if session then
                    session:ProductEquipped(product)
                end
            end)
            PlotService.ObjectRemoved:Connect(function(player: Player, product: Products.Product)
                local session = SessionService.getSession(player)
                if session then
                    session:ProductUnequipped(product)
                end
            end)
            PlotService.BlueprintChanged:Connect(function(player: Player, product: Products.Product, oldProduct: Products.Product)
                local session = SessionService.getSession(player)
                if session then
                    -- Blueprint
                    session:ProductEquipped(product)
                    session:ProductUnequipped(oldProduct)

                    -- Furniture; unequip furniture from old blueprint, equip furnite from new blueprint
                    local oldFurnitureProducts =
                        PlotService.getPlacedFurnitureProducts(player, ProductUtil.getHouseObjectProductData(oldProduct).ObjectKey)
                    local newFurnitureProducts = PlotService.getPlacedFurnitureProducts(player) -- gets from current blueprint

                    for _, oldFurnitureProduct in pairs(oldFurnitureProducts) do
                        session:ProductUnequipped(oldFurnitureProduct)
                    end
                    for _, newFurnitureProduct in pairs(newFurnitureProducts) do
                        session:ProductEquipped(newFurnitureProduct)
                    end
                end
            end)
            SessionService.addLoadCallback(function(player: Player)
                -- Get current furniture as equipped!
                local session = SessionService.getSession(player)
                if session then
                    session:ProductEquipped(PlotService.getBlueprintProduct(player))
                    for _, furnitureProduct in pairs(PlotService.getPlacedFurnitureProducts(player)) do
                        session:ProductEquipped(furnitureProduct)
                    end
                end
            end)
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
