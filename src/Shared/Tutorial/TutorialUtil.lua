local TutorialUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialConstants = require(ReplicatedStorage.Shared.Tutorial.TutorialConstants)
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

function TutorialUtil.getTaskDataAddress(task: string)
    -- ERROR: Bad task
    if not TutorialConstants.Tasks[task] then
        error(("Bad task %q"):format(task))
    end

    return ("Tutorial.%s"):format(task)
end

function TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(colorIndex: number, outfitIndex: number)
    local color = TutorialConstants.StartingAppearance.Colors[colorIndex]
    local outfit = TutorialConstants.StartingAppearance.Outfits[outfitIndex]

    local appearance = TableUtil.deepClone(outfit) :: CharacterItems.Appearance
    appearance.FurColor = { color }

    return appearance
end

return TutorialUtil
