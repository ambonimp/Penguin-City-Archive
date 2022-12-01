local TutorialService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local DataService = require(Paths.Server.Data.DataService)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductService = require(Paths.Server.Products.ProductService)

function TutorialService.completedTask(player: Player, task: string)
    -- RETURN: Already completed!
    if TutorialService.isTaskCompleted(player, task) then
        return
    end

    DataService.set(player, TutorialUtil.getTaskDataAddress(task), true, "TutorialTaskCompleted", {
        Task = task,
    })
end

function TutorialService.isTaskCompleted(player: Player, task: string)
    return DataService.get(player, TutorialUtil.getTaskDataAddress(task)) and true or false
end

-- Communication
Remotes.bindEvents({
    SetStartingAppearance = function(player: Player, dirtyColorIndex: any, dirtyOutfitIndex: any)
        -- Clean Data
        local colorIndex = MathUtil.wrapAround(TypeUtil.toNumber(dirtyColorIndex, 1), #TutorialConstants.StartingAppearance.Colors)
        local outfitIndex = MathUtil.wrapAround(TypeUtil.toNumber(dirtyOutfitIndex, 1), #TutorialConstants.StartingAppearance.Outfits)

        -- Apply Appearance
        local appearance = TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(colorIndex, outfitIndex)
        CharacterItemService.setEquippedCharacterItems(player, appearance)

        -- Give products so user owns this appearance in full!
        for categoryName, itemNames in pairs(appearance) do
            for _, itemName in pairs(itemNames) do
                local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)
                ProductService.addProduct(player, product)
            end
        end

        -- Task done!
        TutorialService.completedTask(player, TutorialConstants.Tasks.StartingAppearance)
    end,
})

return TutorialService
