local MinigameController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ZoneConstans = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Signal = require(Paths.Shared.Signal)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)

type StateData = { [string]: any }
type State = { Name: string, Data: StateData? }
type StateCallback = (StateData) -> ()
type Participants = { Player }

local INITIALIZATION_STATE = { Name = MinigameConstants.States.Nothing }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local currentMinigame: string?
local currentState: State?
local currentZone: ZoneConstans.Zone?
local currentParticipants: Participants?
local currentIsMultiplayer: boolean?

local stateCallbacks: { [string]: { [string]: { Open: StateCallback, Close: StateCallback } } } = { Template = {} }

local maid = Maid.new()

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC MEMBES
-------------------------------------------------------------------------------
MinigameController.ParticipantAdded = Signal.new()
MinigameController.ParticipantRemoved = Signal.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function setState(newState: State)
    local newName: string = newState.Name
    local newData: StateData = newState.Data

    local templateCallbacks = stateCallbacks.Template[newName]

    local lastState = currentState
    currentState = newState

    --print("CLIENT:", newName)

    -- Close previously opened
    if lastState then
        local callbacks = stateCallbacks[currentMinigame][lastState.Name]

        if callbacks and callbacks.Close then
            callbacks.Close(newData)
        elseif templateCallbacks and not callbacks.Open then
            -- If there is no open callback, we can assumed it was opened with an template callback so lets close with one too
            if templateCallbacks.Close then
                templateCallbacks.Close(newData)
            end
        end
    end

    local callbacks = stateCallbacks[currentMinigame][newName]

    if callbacks and callbacks.Open then
        callbacks.Open(newData)
    elseif templateCallbacks and templateCallbacks.Open then
        templateCallbacks.Open(newData)
    end
end

local function assertActiveMinigame()
    assert(currentMinigame, "There is no active minigame")
end

function MinigameController.Start()
    for _, minigame in pairs(MinigameConstants.Minigames) do
        local controller: ModuleScript? = Paths.Client.Minigames[minigame]:FindFirstChild(minigame .. "Controller")
        if controller then
            require(controller)
        end
    end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameController.registerStateCallback(minigame: string, state: string, onOpen: StateCallback?, onClose: StateCallback?)
    local minigameCallbacks = stateCallbacks[minigame]
    if not minigameCallbacks then
        minigameCallbacks = {}
        stateCallbacks[minigame] = minigameCallbacks
    end

    -- ERROR: Attempt to overide state
    if minigameCallbacks[state] then
        error(("Minigame %s has already registered %s state callbacks"):format(minigame, state))
    end

    stateCallbacks[minigame][state] = {
        Open = onOpen,
        Close = onClose,
    }
end

function MinigameController.getMinigame(): string?
    return currentMinigame
end

function MinigameController.getMinigameMaid()
    return maid
end

function MinigameController.isMultiplayer(): boolean
    assertActiveMinigame()
    return currentIsMultiplayer
end

function MinigameController.getState(): string
    assertActiveMinigame()
    return currentState.Name
end

function MinigameController.getData(): StateData
    assertActiveMinigame()
    return currentState.Data
end

function MinigameController.getZone(): ZoneConstans.Zone
    assertActiveMinigame()
    return currentZone
end

function MinigameController.getMap(): Model
    assertActiveMinigame()
    return ZoneUtil.getZoneModel(currentZone):WaitForChild("Map")
end

function MinigameController.getParticpants(): Participants
    assertActiveMinigame()
    return currentParticipants
end

function MinigameController.startCountdownAsync(length: number, onChanged: (value: number) -> ()?): boolean
    assertActiveMinigame()

    local initialState = currentState
    length = math.max(0, currentState.Data.StartTime + length - Workspace:GetServerTimeNow()) -- Syncs with server

    if onChanged then
        onChanged(math.ceil(length))
    end

    task.wait(length % 1)
    length = math.floor(length)
    while length > 0 and initialState == currentState do
        if onChanged then
            onChanged(length)
        end

        task.wait(1)
        length -= 1
    end

    return length == 0
end

function MinigameController.getOwnPlacement(scores: MinigameConstants.SortedScores): number
    return TableUtil.findFromProperty(scores, "Player", player)
end

function MinigameController.getOwnScore(scores: MinigameConstants.SortedScores): number
    return scores[MinigameController.getOwnPlacement(scores)].Score
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
Remotes.bindEvents({
    MinigameJoined = function(id: string, minigame: string, state: State, participants: Participants, isMultiplayer: boolean)
        currentMinigame = minigame
        currentZone = ZoneUtil.zone(ZoneConstans.ZoneType.Minigame, id)
        currentParticipants = participants
        currentIsMultiplayer = isMultiplayer

        if state.Name ~= INITIALIZATION_STATE.Name then
            setState(INITIALIZATION_STATE)
        end
        setState(state)
        uiStateMachine:Push(UIConstants.States.Minigame)
    end,

    MinigameExited = function()
        maid:Cleanup()
        currentMinigame = nil
        currentZone = nil :: ZoneConstans.Zone -- ahh
        currentState = nil
        currentParticipants = nil
        currentIsMultiplayer = nil
    end,

    MinigameParticipantAdded = function(participant: Player)
        table.insert(currentParticipants, participant)
        MinigameController.ParticipantAdded:Fire(participant)
    end,

    MinigameParticipantRemoved = function(participant: Player)
        table.remove(currentParticipants, table.find(currentParticipants, participant))
        MinigameController.ParticipantRemoved:Fire(participant)
    end,

    MinigameStateChanged = function(state: State)
        setState(state)
    end,
})

return MinigameController
