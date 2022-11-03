local MinigameController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local ZoneConstans = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Signal = require(Paths.Shared.Signal)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

type StateData = { [string]: any }
type State = { Name: string, Data: StateData }
type StateCallback = (StateData) -> ()

type Participants = { Player }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local currentMinigame: string?
local currentState: State?
local currentZone: ZoneConstans.Zone?
local currentParticipants: Participants?
local currentIsMultiplayer: boolean?

local stateCallbacks: { [string]: { [string]: { Open: StateCallback, Close: StateCallback } } } = { Template = {} }

local maid = Maid.new()

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

    print("CLIENT:", newName)

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
        onChanged(length)
    end

    while length > 0 and initialState == currentState do
        length -= 1

        if onChanged then
            onChanged(length)
        end
    end

    return length == 0
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
        setState(state)
    end,
    MinigameExited = function()
        maid:Cleanup()

        currentMinigame = nil
        currentZone = nil :: ZoneConstans.Zone -- ahh
        currentState = nil
        currentParticipants = nil
        currentIsMultiplayer = nil
    end,
    MinigameParticipantAdded = function(player: Player)
        table.insert(currentParticipants, player)
        MinigameController.ParticipantAdded:Fire(player)
    end,
    MinigameParticipantRemoved = function(player: Player)
        table.remove(currentParticipants, table.find(currentParticipants, player))
        MinigameController.ParticipantRemoved:Fire(player)
    end,
    MinigameStateChanged = function(state: State)
        print(state.Data.StartTime)
        setState(state)
    end,
})

return MinigameController
