local MinigameController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Promise = require(Paths.Packages.promise)
local Maid = require(Paths.Shared.Maid)
local Remotes = require(Paths.Shared.Remotes)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Signal = require(Paths.Shared.Signal)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local UIConstants = require(Paths.Client.UI.UIConstants)
local MinigameQueueScreen = require(Paths.Client.UI.Screens.Minigames.MinigameQueueScreen)
local UIController = require(Paths.Client.UI.UIController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local Output = require(Paths.Shared.Output)
local Sound = require(Paths.Shared.Sound)

type Music = "Core" | "Intermission"
type StateData = { [string]: any }
type State = { Name: string, Data: StateData? }
type StateCallback = (StateData) -> ()
type Participants = { Player }

local STATES = MinigameConstants.States
local INITIALIZATION_STATE = { Name = STATES.Nothing }
-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local currentMinigame: string?
local currentState: State?
local currentZone: ZoneConstants.Zone?
local currentParticipants: Participants?
local currentIsMultiplayer: boolean?

local stateCallbacks: { [string]: { [string]: { Open: StateCallback, Close: StateCallback } } } = {}

local maid = Maid.new()
local uiStateMachine = UIController.getStateMachine()

local music: { [string]: Sound } = {}

local tasks

-------------------------------------------------------------------------------
-- PUBLIC MEMBES
-------------------------------------------------------------------------------
MinigameController.ParticipantAdded = Signal.new()
MinigameController.ParticipantRemoved = Signal.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
function MinigameController.playMusic(name: Music)
    -- RETURN: Music already playing
    if music[name] then
        return
    end

    music[name] = Sound.play(if name == "Intermission" then "MinigameIntermission" else currentMinigame, true)
end

function MinigameController.stopMusic(name: Music)
    local sound = music[name]
    if sound then
        Sound.fadeOut(music[name], nil, true)
        music[name] = nil
    end
end

local function setState(newState: State)
    task.spawn(function()
        local newName: string = newState.Name
        local newData: StateData = newState.Data

        local lastState = currentState
        currentState = newState

        Output.doDebug(MinigameConstants.DoDebug, "Minigame state changed:", newName)

        -- Close previously opened
        if lastState then
            local callbacks = stateCallbacks[currentMinigame][lastState.Name]

            if callbacks and callbacks.Close then
                callbacks.Close(newData)
            end
        end

        local callbacks = stateCallbacks[currentMinigame][newName]
        if callbacks and callbacks.Open then
            callbacks.Open(newData)
        end
    end)
end

local function assertActiveMinigame()
    assert(currentMinigame, "There is no active minigame")
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameController.Start()
    for _, minigame in pairs(MinigameConstants.Minigames) do
        local controller: ModuleScript? = Paths.Client.Minigames[minigame]:FindFirstChild(minigame .. "Controller")
        if controller then
            require(controller)
        end
    end
end

-- Yields
function MinigameController.playRequest(minigame: string, isMultiplayer: boolean, queueStation: Model?)
    Remotes.invokeServer("MinigamePlayRequested", minigame, isMultiplayer, queueStation)
end

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

function MinigameController.getZone(): ZoneConstants.Zone | nil
    assertActiveMinigame()
    return currentZone
end

function MinigameController.getMap(): Model | nil
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

function MinigameController.isNewBest(scores: MinigameConstants.SortedScores): boolean
    return scores[MinigameController.getOwnPlacement(scores)].NewBest ~= nil
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
Remotes.bindEvents({
    MinigameJoined = function(id: string, minigame: string, state: State, participants: Participants, isMultiplayer: boolean)
        MinigameQueueScreen.close()

        currentMinigame = minigame
        currentZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Minigame, ZoneConstants.ZoneType.Minigame[minigame], id)
        currentParticipants = participants
        currentIsMultiplayer = isMultiplayer

        tasks = Promise.new(function(resolve)
            if not ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), currentZone) then
                ZoneController.ZoneChanged:Wait()
            end

            if state.Name ~= INITIALIZATION_STATE.Name then
                setState(INITIALIZATION_STATE)
            end

            setState(state)

            uiStateMachine:Push(UIConstants.States.Minigame)
            resolve()
        end)
    end,

    MinigameExited = function()
        tasks = tasks:andThen(function()
            -- Music
            MinigameController.stopMusic("Core")
            MinigameController.stopMusic("Intermission")

            -- Try catch at the peak of the transition to hide its removal
            maid:GiveTask(ZoneController.ZoneChanged:Connect(function()
                uiStateMachine:Remove(UIConstants.States.Minigame)
            end))

            if ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), currentZone) then
                ZoneController.ZoneChanged:Wait()
            end

            maid:Cleanup()
            uiStateMachine:Remove(UIConstants.States.Minigame) -- Security incase ZoneChanged block doesn't run

            task.defer(function()
                currentMinigame = nil
                currentZone = nil :: ZoneConstants.Zone -- ahh
                currentState = nil
                currentParticipants = nil
                currentIsMultiplayer = nil
            end)

            tasks = nil
        end)
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
        tasks = tasks:andThenCall(setState, state)
    end,
})

return MinigameController
