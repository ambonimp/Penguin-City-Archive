local VoldexLoading = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

local LETTERS = { "V", "O", "L", "D", "E", "X" }
local SCALE_POSITION_OFFSET = 0.25 --How much we +- to Y position scale at peak on Y axis of sinewave
local SINE_WAVE = {
    SPEED_SECONDS = 3.5, -- How long for 1 letter to cycle through 0 to 360 deg
    LETTER_OFFSET = -0.7, -- How many seconds offset is a letter from its neighbour
}

local voldexLoadingFrame: Frame = Paths.UI:WaitForChild("SpecialEffects").VoldexLoading
local imageLabelsByLetter: { [string]: ImageLabel } = {}
local hideShowInstances: { Instance } = ArrayUtil.merge({ voldexLoadingFrame }, voldexLoadingFrame:GetDescendants())

local isOpen = false

function VoldexLoading.open(tweenInfo: TweenInfo)
    -- RETURN: Already open
    if isOpen then
        return
    end
    isOpen = true

    InstanceUtil.show(hideShowInstances, tweenInfo)
end

function VoldexLoading.close(tweenInfo: TweenInfo)
    -- RETURN: Not open
    if not isOpen then
        return
    end
    isOpen = false

    InstanceUtil.hide(hideShowInstances, tweenInfo)
end

-- Animation Loop
local startTick = tick()
RunService.RenderStepped:Connect(function()
    local globalTimeElapsed = (tick() - startTick) % SINE_WAVE.SPEED_SECONDS -- How long has elapsed in this iteration of sinewave
    for i, letter in ipairs(LETTERS) do
        local letterImageLabel = imageLabelsByLetter[letter]

        local localTimeElapsed = (globalTimeElapsed + (i - 1) * SINE_WAVE.LETTER_OFFSET) % SINE_WAVE.SPEED_SECONDS
        local yOffset = SCALE_POSITION_OFFSET * math.sin(math.rad((localTimeElapsed / SINE_WAVE.SPEED_SECONDS) * 360))

        letterImageLabel.Position = UDim2.fromScale(0.5, 0.5 + yOffset)
    end
end)

-------------------------------------------------------------------------------
-- Starter Logic
-------------------------------------------------------------------------------

-- Get letters
do
    for _, descendant in pairs(voldexLoadingFrame:GetDescendants()) do
        if descendant:IsA("ImageLabel") and table.find(LETTERS, descendant.Parent.Name) then
            imageLabelsByLetter[descendant.Parent.Name] = descendant
        end
    end

    -- ERROR: Missing letter
    if TableUtil.length(imageLabelsByLetter) ~= #LETTERS then
        error(
            ("Missing Letters. Found ImageLabels: %s"):format(
                StringUtil.listWords(TableUtil.mapValues(TableUtil.toArray(imageLabelsByLetter), function(value: ImageLabel)
                    return value:GetFullName()
                end))
            )
        )
    end
end

-- Hide
InstanceUtil.hide(hideShowInstances)
voldexLoadingFrame.Visible = true

return VoldexLoading
