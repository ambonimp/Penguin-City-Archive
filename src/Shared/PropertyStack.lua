--[[
    This file allows us to "stack" properties on Roblox Instances
    
    Example:
    We want to disable collisions when a player is in the character editor.
    We want to disable collisions when a player has teleported to a new zone.
    
    Both of these require changing the `CollisionGroupId` of the player Character, but could also both be "activated" at the same time
    (player edits their character just after teleporting to a new zone). How do we handle `CollisionGroupId` when these 2 scopes don't know
        about one another?
        
    We can set the `CollisionGroupId` property through PropertyStack, which retains memory for us!
]]
local PropertyStack = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

type KeyValuePair = { Key: string, Value: any }
type PropertyState = { DefaultValue: any, KeyData: { [number]: { KeyValuePair } } } -- Keys in KeyData are keyPriority
type InstanceMemory = { DestroyingConnection: RBXScriptConnection, PropertyStates: { [string]: PropertyState } } -- Keys are property names

local DEFAULT_PRIORITY = 0

local memory: { [Instance]: InstanceMemory } = {}

-------------------------------------------------------------------------------
-- Internal Functions
-------------------------------------------------------------------------------

local function updateProperty(instance: Instance, propertyName: string)
    -- Output.debug("updateProperty", instance, propertyName)

    -- WARN: No memory?
    local instanceMemory = memory[instance]
    if not instanceMemory then
        warn("No instance memory?")
        return
    end

    local propertyState = instanceMemory.PropertyStates[propertyName]
    if propertyState then
        -- Get highest priority key-value pair
        local highestPriority: number
        local highestKeyValuePair: KeyValuePair
        for keyPriority, keyValuePairs in pairs(propertyState.KeyData) do
            local chosenKeyValuePair = keyValuePairs[1]
            if chosenKeyValuePair then
                if not highestPriority or keyPriority > highestPriority then
                    highestPriority = keyPriority
                    highestKeyValuePair = chosenKeyValuePair
                end
            else
                propertyState.KeyData[keyPriority] = nil
            end
        end

        if highestKeyValuePair then
            -- Output.debug("updateInstance", instanceMemory, propertyName, "->", highestKeyValuePair.Key, highestKeyValuePair.Value)
            instance[propertyName] = highestKeyValuePair.Value
        else
            -- Output.debug("updateInstance", instanceMemory, propertyName, "->", "DEFAULT", propertyState.DefaultValue)
            instance[propertyName] = propertyState.DefaultValue
            instanceMemory.PropertyStates[propertyName] = nil
        end
    end
end

local function updateInstance(instance: Instance, propertyName: string?)
    -- Output.debug("updateInstance", instance)

    -- WARN: No memory?
    local instanceMemory = memory[instance]
    if not instanceMemory then
        warn("No instance memory?")
        return
    end

    -- Update properties
    if propertyName then
        updateProperty(instance, propertyName)
    else
        for somePropertyName, _ in pairs(instanceMemory.PropertyStates) do
            updateProperty(instance, somePropertyName)
        end
    end

    -- Clean cache if empty
    if TableUtil.isEmpty(instanceMemory.PropertyStates) then
        instanceMemory.DestroyingConnection:Disconnect()
        memory[instance] = nil

        -- Output.debug("updateInstance", instanceMemory, "memory was empty")
    end
end

local function setupMemory(instance: Instance)
    -- Circular Dependency
    local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

    local instanceMemory: InstanceMemory = {
        DestroyingConnection = InstanceUtil.onDestroyed(instance, function()
            memory[instance] = nil
        end),
        PropertyStates = {},
    }

    memory[instance] = instanceMemory
    return instanceMemory
end

local function setupPropertyState(instance: Instance, propertyName: string)
    local propertyState = {
        DefaultValue = instance[propertyName],
        KeyData = {},
    }

    memory[instance].PropertyStates[propertyName] = propertyState
    return propertyState
end

local function addKeyValuePair(propertyState: PropertyState, keyPriority: number, keyValuePair: KeyValuePair)
    local keyValuePairs = propertyState.KeyData[keyPriority]
    if not keyValuePairs then
        keyValuePairs = {}
        propertyState.KeyData[keyPriority] = keyValuePairs
    end

    table.insert(keyValuePairs, keyValuePair)
end

local function removeKeyValuePair(propertyState: PropertyState, key: string)
    for _, keyValuePairs in pairs(propertyState.KeyData) do
        for index, keyValuePair in pairs(keyValuePairs) do
            if keyValuePair.Key == key then
                table.remove(keyValuePairs, index)
                return
            end
        end
    end
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

--[[
    Keys of equal priority.. priority is given to the key set first
    
    - `keyPriority`: Higher values get priority over lower values. Default value is 0.
]]
function PropertyStack.setProperty(instance: Instance, propertyName: string, propertyValue: any, key: string, keyPriority: number?)
    -- Output.debug("setProperty", instance, propertyName, propertyValue, key, keyPriority)

    -- Get InstanceMemory
    local instanceMemory = memory[instance]
    if not instanceMemory then
        instanceMemory = setupMemory(instance)
    end

    -- Get PropertyState
    local propertyState = instanceMemory.PropertyStates[propertyName]
    if not propertyState then
        propertyState = setupPropertyState(instance, propertyName)
    end

    -- Update existing KeyValuePair
    keyPriority = keyPriority or DEFAULT_PRIORITY
    local foundExistingPair = false
    for someKeyPriority, keyValuePairs in pairs(propertyState.KeyData) do
        for _, keyValuePair in pairs(keyValuePairs) do
            if keyValuePair.Key == key then
                -- Update Value
                keyValuePair.Value = propertyValue

                -- Move if new priority
                if someKeyPriority ~= keyPriority then
                    removeKeyValuePair(propertyState, key)
                    addKeyValuePair(propertyState, keyPriority, keyValuePair)
                end

                -- Exit Loop
                foundExistingPair = true
                break
            end
        end

        if foundExistingPair then
            break
        end
    end

    -- Create new KeyValuePair
    if not foundExistingPair then
        local keyValuePair: KeyValuePair = {
            Key = key,
            Value = propertyValue,
        }
        addKeyValuePair(propertyState, keyPriority, keyValuePair)
    end

    updateInstance(instance, propertyName)
end

function PropertyStack.clearProperty(instance: Instance, propertyName: string, key: string)
    -- Output.debug("clearProperty 1", instance, propertyName, key, memory[instance])

    -- Get InstanceMemory
    local instanceMemory = memory[instance]
    if not instanceMemory then
        return
    end

    -- Get PropertyState
    local propertyState = instanceMemory.PropertyStates[propertyName]
    if not propertyState then
        return
    end

    removeKeyValuePair(propertyState, key)

    updateInstance(instance)
    -- Output.debug("clearProperty 2", instance, propertyName, key, memory[instance])
end

function PropertyStack.setProperties(instance: Instance, propertyTable: { [string]: any }, key: string, keyPriority: number?)
    for propertyName, propertyValue in pairs(propertyTable) do
        PropertyStack.setProperty(instance, propertyName, propertyValue, key, keyPriority)
    end
end

function PropertyStack.clearProperties(instance: Instance, propertyTable: { [string]: any }, key: string)
    for propertyName, _propertyValue in pairs(propertyTable) do
        PropertyStack.clearProperty(instance, propertyName, key)
    end
end

--[[
    Returns the original value of `instance[propertyName]` before it was passed over to PropertyStack.

    If it has not been passed over to PropertyStack, will return its current value!
]]
function PropertyStack.getDefaultValue(instance: Instance, propertyName: string)
    -- Get InstanceMemory
    local instanceMemory = memory[instance]
    if not instanceMemory then
        return instance[propertyName]
    end

    -- Get PropertyState
    local propertyState = instanceMemory.PropertyStates[propertyName]
    if not propertyState then
        return instance[propertyName]
    end

    return propertyState.DefaultValue
end

return PropertyStack
