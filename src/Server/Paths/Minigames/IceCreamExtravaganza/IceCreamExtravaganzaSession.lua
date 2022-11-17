local IceCreamExtravaganzaSession = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local PropertyStack = require(Paths.Shared.PropertyStack)
local CharacterController = require(Paths.Server.Characters.CharacterService)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local Output = require(Paths.Shared.Output)

local MINIGAME_NAME = "IceCreamExtravaganza"

function IceCreamExtravaganzaSession.new(id: string, participants: { Player }, isMultiplayer: boolean)
    local minigameSession = MinigameSession.new(MINIGAME_NAME, id, participants, isMultiplayer)

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local coreMaid = Maid.new()
    local maid = minigameSession:GetMaid()
    maid:GiveTask(coreMaid)

    local map = minigameSession:GetMap()
    local spawnPoints = map.PlayerSpawns:GetChildren()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function spawnCharacter(participant: Player)
        local character: Model = participant.Character

        PropertyStack.setProperty(character.Humanoid, "WalkSpeed", IceCreamExtravaganzaConstants.WalkSpeed, MINIGAME_NAME, math.huge)
        CharacterController.standOn(character, spawnPoints[table.find(participants, participant)])
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    minigameSession.ParticipantAdded:Connect(function(participant: Player)
        spawnCharacter(participant)
    end)

    minigameSession.ParticipantRemoved:Connect(function(participant: Player, stillInGame: boolean)
        if stillInGame then
            local character: Model = participant.Character
            CharacterUtil.unanchor(character)
        end
    end)

    -------------------------------------------------------------------------------
    -- State handlers
    -------------------------------------------------------------------------------
    minigameSession:RegisterStateCallbacks(MinigameConstants.States.Core, function() end)

    minigameSession:SetDefaultScore(0)
    minigameSession:Start()

    return minigameSession
end

-- Communication
do
    Remotes.declareEvent("IceCreamExtravaganzaRecipeTypeOrder")
    Remotes.declareEvent("IceCreamExtravaganzaPizzaCompleted")
    Remotes.declareEvent("PizzaMinigameRoundFinished")
end

return IceCreamExtravaganzaSession
