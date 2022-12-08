--[[
    Applies attributes to Players so clients know how to display chat messages
]]
local PlayerChatService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlayerService = require(Paths.Server.PlayerService)
local CharacterItemService = require(Paths.Server.Characters.CharacterItemService)
local PlayerConstants = require(Paths.Shared.Constants.PlayerConstants)

local function writeAttributes(player: Player)
    -- Get Information
    local aestheticRoleDetails = PlayerService.getAestheticRoleDetails(player)
    local furColorName = CharacterItemService.getEquippedCharacterItems(player).FurColor[1] :: string

    -- Write
    player:SetAttribute(PlayerConstants.Chat.PlayerAttributes.FurColor, furColorName)
    player:SetAttribute(PlayerConstants.Chat.PlayerAttributes.Role, aestheticRoleDetails and aestheticRoleDetails.Name)
end

function PlayerChatService.loadPlayer(player: Player)
    writeAttributes(player)
end

CharacterItemService.ItemEquipped:Connect(function(player: Player, categoryName: string, _itemName: string)
    if categoryName == "FurColor" then
        writeAttributes(player)
    end
end)

return PlayerChatService
