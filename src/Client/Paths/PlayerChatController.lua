--[[
    Applies custom formatting to chat messages on a per player basis

    - Chat Tags
    - Penguin Colors
]]
local PlayerChatController = {}

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local FurColorConstants = require(Paths.Shared.CharacterItems.CharacterItemConstants.FurColorConstants)
local PlayerConstants = require(Paths.Shared.Constants.PlayerConstants)

local DEFAULT_FUR_COLOR = Color3.fromRGB(255, 255, 255)
local COLOR_BLACK = Color3.fromRGB(0, 0, 0)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

-- Returns a stroke color that will make `color` pop
local function getStrokeColor(color: Color3)
    local highestVal = math.max(color.B, color.G, color.R)
    if highestVal > 80 / 255 then
        return COLOR_BLACK
    end

    return COLOR_WHITE
end

-- Applies pretty formatting to our messages
local function onIncomingMessage(message: TextChatMessage)
    local properties = Instance.new("TextChatMessageProperties")

    -- RETURN: No player?
    local player = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
    if not player then
        return
    end

    -- Get Information
    local furColorName = player:GetAttribute(PlayerConstants.Chat.PlayerAttributes.FurColor)
    local aestheticRoleName = player:GetAttribute(PlayerConstants.Chat.PlayerAttributes.Role)

    local furColorDetails = FurColorConstants.Items[furColorName]
    local furColor = furColorDetails and furColorDetails.Color or DEFAULT_FUR_COLOR
    local aestheticRoleDetails = PlayerConstants.AestheticRoleDetails[aestheticRoleName] or nil

    -- Update Message
    do
        local prefixText = message.PrefixText

        -- Fur Color
        prefixText = string.format(
            "<stroke color='#%s' transparency='0.5'><font color='#%s'>%s</font></stroke>",
            getStrokeColor(furColor):ToHex(),
            furColor:ToHex(),
            prefixText
        )

        -- Role
        if aestheticRoleDetails then
            prefixText = ("%s %s"):format(aestheticRoleDetails.Emoji, prefixText)
        end

        properties.PrefixText = prefixText
    end

    return properties
end

TextChatService.OnIncomingMessage = onIncomingMessage :: any

return PlayerChatController
