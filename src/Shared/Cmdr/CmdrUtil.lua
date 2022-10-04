local CmdrUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Permissions = require(ReplicatedStorage.Shared.Permissions)

function CmdrUtil.IsAdmin(player: Player)
    return Permissions.isAdmin(player)
end

function CmdrUtil.createTypeDefinition(name: string, stringsGetter: () -> { string }, stringToObject: (text: string) -> any)
    return {
        Transform = function(text: string, _executor: Player)
            return CmdrUtil.MakeFuzzyFinder(stringsGetter())(text)
        end,
        Validate = function(fuzzyResults: { string })
            return #fuzzyResults > 0, ("No valid %q found"):format(name)
        end,
        Autocomplete = function(fuzzyResults: { string })
            return fuzzyResults
        end,
        Parse = function(fuzzyResults: { string })
            return stringToObject(fuzzyResults[1])
        end,
        Default = function()
            return stringsGetter()[1]
        end,
    }
end

-- IMPORTED FROM CMDR
do
    --- Takes an array and flips its values into dictionary keys with fuzzyResults of true.
    function CmdrUtil.MakeDictionary(array)
        local dictionary = {}

        for i = 1, #array do
            dictionary[array[i]] = true
        end

        return dictionary
    end

    --- Takes a dictionary and returns its keys.
    function CmdrUtil.DictionaryKeys(dict)
        local keys = {}

        for key in pairs(dict) do
            table.insert(keys, key)
        end

        return keys
    end

    -- Takes an array of instances and returns (array<names>, array<instances>)
    local function transformInstanceSet(instances)
        local names = {}

        for i = 1, #instances do
            names[i] = instances[i].Name
        end

        return names, instances
    end

    --- Returns a function that is a fuzzy finder for the specified set or container.
    -- Can pass an array of strings, array of instances, array of EnumItems,
    -- array of dictionaries with a Name key or an instance (in which case its children will be used)
    -- Exact matches will be inserted in the front of the resulting array
    function CmdrUtil.MakeFuzzyFinder(setOrContainer)
        local names
        local instances = {}

        if typeof(setOrContainer) == "Enum" then
            setOrContainer = setOrContainer:GetEnumItems()
        end

        if typeof(setOrContainer) == "Instance" then
            names, instances = transformInstanceSet(setOrContainer:GetChildren())
        elseif typeof(setOrContainer) == "table" then
            if
                typeof(setOrContainer[1]) == "Instance"
                or typeof(setOrContainer[1]) == "EnumItem"
                or (typeof(setOrContainer[1]) == "table" and typeof(setOrContainer[1].Name) == "string")
            then
                names, instances = transformInstanceSet(setOrContainer)
            elseif type(setOrContainer[1]) == "string" then
                names = setOrContainer
            elseif setOrContainer[1] ~= nil then
                error("MakeFuzzyFinder only accepts tables of instances or strings.")
            else
                names = {}
            end
        else
            error("MakeFuzzyFinder only accepts a table, Enum, or Instance.")
        end

        -- Searches the set (checking exact matches first)
        return function(text, returnFirst)
            local results = {}

            for i, name in pairs(names) do
                local fuzzyResults = instances and instances[i] or name

                -- Continue on checking for non-exact matches...
                -- Still need to loop through everything, even on returnFirst, because possibility of an exact match.
                if name:lower() == text:lower() then
                    if returnFirst then
                        return fuzzyResults
                    else
                        table.insert(results, 1, fuzzyResults)
                    end
                elseif name:lower():sub(1, #text) == text:lower() then
                    results[#results + 1] = fuzzyResults
                end
            end

            if returnFirst then
                return results[1]
            end

            return results
        end
    end

    --- Takes an array of instances and returns an array of those instances' names.
    function CmdrUtil.GetNames(instances)
        local names = {}

        for i = 1, #instances do
            names[i] = instances[i].Name or tostring(instances[i])
        end

        return names
    end

    --- Splits a string using a simple separator (no quote parsing)
    function CmdrUtil.SplitStringSimple(inputstr, sep)
        if sep == nil then
            sep = "%s"
        end
        local t = {}
        local i = 1
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            t[i] = str
            i = i + 1
        end
        return t
    end

    local function charCode(n)
        return utf8.char(tonumber(n, 16))
    end

    --- Parses escape sequences into their fully qualified characters
    function CmdrUtil.ParseEscapeSequences(text)
        return text:gsub("\\(.)", {
            t = "\t",
            n = "\n",
        })
            :gsub("\\u(%x%x%x%x)", charCode)
            :gsub("\\x(%x%x)", charCode)
    end

    function CmdrUtil.EncodeEscapedOperator(text, op)
        local first = op:sub(1, 1)
        local escapedOp = op:gsub(".", "%%%1")
        local escapedFirst = "%" .. first

        return text:gsub("(" .. escapedFirst .. "+)(" .. escapedOp .. ")", function(esc, op)
            return (esc:sub(1, #esc - 1) .. op):gsub(".", function(char)
                return "\\u" .. string.format("%04x", string.byte(char), 16)
            end)
        end)
    end

    local OPERATORS = { "&&", "||", ";" }
    function CmdrUtil.EncodeEscapedOperators(text)
        for _, operator in ipairs(OPERATORS) do
            text = CmdrUtil.EncodeEscapedOperator(text, operator)
        end

        return text
    end

    local function encodeControlChars(text)
        return (
            text:gsub("\\\\", "___!CMDR_ESCAPE!___")
                :gsub('\\"', "___!CMDR_QUOTE!___")
                :gsub("\\'", "___!CMDR_SQUOTE!___")
                :gsub("\\\n", "___!CMDR_NL!___")
        )
    end

    local function decodeControlChars(text)
        return (text:gsub("___!CMDR_ESCAPE!___", "\\"):gsub("___!CMDR_QUOTE!___", '"'):gsub("___!CMDR_NL!___", "\n"))
    end

    --- Splits a string by space but taking into account quoted sequences which will be treated as a single argument.
    function CmdrUtil.SplitString(text, max)
        text = encodeControlChars(text)
        max = max or math.huge
        local t = {}
        local spat, epat = [=[^(['"])]=], [=[(['"])$]=]
        local buf, quoted
        for str in text:gmatch("[^ ]+") do
            str = CmdrUtil.ParseEscapeSequences(str)
            local squoted = str:match(spat)
            local equoted = str:match(epat)
            local escaped = str:match([=[(\*)['"]$]=])
            if squoted and not quoted and not equoted then
                buf, quoted = str, squoted
            elseif buf and equoted == quoted and #escaped % 2 == 0 then
                str, buf, quoted = buf .. " " .. str, nil, nil
            elseif buf then
                buf = buf .. " " .. str
            end
            if not buf then
                t[#t + (#t > max and 0 or 1)] = decodeControlChars(str:gsub(spat, ""):gsub(epat, ""))
            end
        end

        if buf then
            t[#t + (#t > max and 0 or 1)] = decodeControlChars(buf)
        end

        return t
    end

    --- Takes an array of arguments and a max fuzzyResults.
    -- Any indicies past the max fuzzyResults will be appended to the last valid argument.
    function CmdrUtil.MashExcessArguments(arguments, max)
        local t = {}
        for i = 1, #arguments do
            if i > max then
                t[max] = ("%s %s"):format(t[max] or "", arguments[i])
            else
                t[i] = arguments[i]
            end
        end
        return t
    end

    --- Trims whitespace from both sides of a string.
    function CmdrUtil.TrimString(str)
        local _, from = string.find(str, "^%s*")
        -- trim the string in two steps to prevent quadratic backtracking when no "%S" match is found
        return from == #str and "" or string.match(str, ".*%S", from + 1)
    end

    --- Returns the text bounds size based on given text, label (from which properties will be pulled), and optional Vector2 container size.
    function CmdrUtil.GetTextSize(text, label, size)
        return TextService:GetTextSize(text, label.TextSize, label.Font, size or Vector2.new(label.AbsoluteSize.X, 0))
    end

    --- Makes an Enum type.
    function CmdrUtil.MakeEnumType(name, values)
        local findValue = CmdrUtil.MakeFuzzyFinder(values)
        return {
            Validate = function(text)
                return findValue(text, true) ~= nil, ("Value %q is not a valid %s."):format(text, name)
            end,
            Autocomplete = function(text)
                local list = findValue(text)
                return type(list[1]) ~= "string" and CmdrUtil.GetNames(list) or list
            end,
            Parse = function(text)
                return findValue(text, true)
            end,
        }
    end

    --- Parses a prefixed union type argument (such as %Team)
    function CmdrUtil.ParsePrefixedUnionType(typeValue, rawValue)
        local split = CmdrUtil.SplitStringSimple(typeValue)

        -- Check prefixes in order from longest to shortest
        local types = {}
        for i = 1, #split, 2 do
            types[#types + 1] = {
                prefix = split[i - 1] or "",
                type = split[i],
            }
        end

        table.sort(types, function(a, b)
            return #a.prefix > #b.prefix
        end)

        for i = 1, #types do
            local t = types[i]

            if rawValue:sub(1, #t.prefix) == t.prefix then
                return t.type, rawValue:sub(#t.prefix + 1), t.prefix
            end
        end
    end

    --- Creates a listable type from a singlular type
    function CmdrUtil.MakeListableType(type, override)
        local listableType = {
            Listable = true,
            Transform = type.Transform,
            Validate = type.Validate,
            ValidateOnce = type.ValidateOnce,
            Autocomplete = type.Autocomplete,
            Default = type.Default,
            Parse = function(...)
                return { type.Parse(...) }
            end,
        }

        if override then
            for key, fuzzyResults in pairs(override) do
                listableType[key] = fuzzyResults
            end
        end

        return listableType
    end

    local function encodeCommandEscape(text)
        return (text:gsub("\\%$", "___!CMDR_DOLLAR!___"))
    end

    local function decodeCommandEscape(text)
        return (text:gsub("___!CMDR_DOLLAR!___", "$"))
    end

    function CmdrUtil.RunCommandString(dispatcher, commandString)
        commandString = CmdrUtil.ParseEscapeSequences(commandString)
        commandString = CmdrUtil.EncodeEscapedOperators(commandString)

        local commands = commandString:split("&&")

        local output = ""
        for i, command in ipairs(commands) do
            local outputEncoded = output:gsub("%$", "\\x24")
            command = command:gsub("||", output:find("%s") and ("%q"):format(outputEncoded) or outputEncoded)

            output = tostring(dispatcher:EvaluateAndRun((CmdrUtil.RunEmbeddedCommands(dispatcher, command))))

            if i == #commands then
                return output
            end
        end
    end

    --- Runs embedded commands and replaces them
    function CmdrUtil.RunEmbeddedCommands(dispatcher, str)
        str = encodeCommandEscape(str)

        local results = {}
        -- We need to do this because you can't yield in the gsub function
        for text in str:gmatch("$(%b{})") do
            local doQuotes = true
            local commandString = text:sub(2, #text - 1)

            if commandString:match("^{.+}$") then -- Allow double curly for literal replacement
                doQuotes = false
                commandString = commandString:sub(2, #commandString - 1)
            end

            results[text] = CmdrUtil.RunCommandString(dispatcher, commandString)

            if doQuotes then
                if results[text]:find("%s") or results[text] == "" then
                    results[text] = string.format("%q", results[text])
                end
            end
        end

        return decodeCommandEscape(str:gsub("$(%b{})", results))
    end

    --- Replaces arguments in the format $1, $2, $something with whatever the
    -- given function returns for it.
    function CmdrUtil.SubstituteArgs(str, replace)
        str = encodeCommandEscape(str)
        -- Convert numerical keys to strings
        if type(replace) == "table" then
            for i = 1, #replace do
                local k = tostring(i)
                replace[k] = replace[i]

                if replace[k]:find("%s") then
                    replace[k] = string.format("%q", replace[k])
                end
            end
        end
        return decodeCommandEscape(str:gsub("($%d+)%b{}", "%1"):gsub("$(%w+)", replace))
    end

    --- Creates an alias command
    function CmdrUtil.MakeAliasCommand(name, commandString)
        local commandName, commandDescription = unpack(name:split("|"))
        local args = {}

        commandString = CmdrUtil.EncodeEscapedOperators(commandString)

        local seenArgs = {}

        for arg in commandString:gmatch("$(%d+)") do
            if seenArgs[arg] == nil then
                seenArgs[arg] = true
                local options = commandString:match("$" .. arg .. "(%b{})")

                local argType, argName, argDescription
                if options then
                    options = options:sub(2, #options - 1) -- remove braces
                    argType, argName, argDescription = unpack(options:split("|"))
                end

                argType = argType or "string"
                argName = argName or ("Argument " .. arg)
                argDescription = argDescription or ""

                table.insert(args, {
                    Type = argType,
                    Name = argName,
                    Description = argDescription,
                })
            end
        end

        return {
            Name = commandName,
            Aliases = {},
            Description = "<Alias> " .. (commandDescription or commandString),
            Group = "UserAlias",
            Args = args,
            Run = function(context)
                return CmdrUtil.RunCommandString(context.Dispatcher, CmdrUtil.SubstituteArgs(commandString, context.RawArguments))
            end,
        }
    end

    --- Makes a type that contains a sequence, e.g. Vector3 or Color3
    function CmdrUtil.MakeSequenceType(options)
        options = options or {}

        assert(options.Parse ~= nil or options.Constructor ~= nil, "MakeSequenceType: Must provide one of: Constructor, Parse")

        options.TransformEach = options.TransformEach or function(...)
            return ...
        end

        options.ValidateEach = options.ValidateEach or function()
            return true
        end

        return {
            Prefixes = options.Prefixes,

            Transform = function(text)
                return CmdrUtil.Map(CmdrUtil.SplitPrioritizedDelimeter(text, { ",", "%s" }), function(fuzzyResults)
                    return options.TransformEach(fuzzyResults)
                end)
            end,

            Validate = function(components)
                if options.Length and #components > options.Length then
                    return false, ("Maximum of %d values allowed in sequence"):format(options.Length)
                end

                for i = 1, options.Length or #components do
                    local valid, reason = options.ValidateEach(components[i], i)

                    if not valid then
                        return false, reason
                    end
                end

                return true
            end,

            Parse = options.Parse or function(components)
                return options.Constructor(unpack(components))
            end,
        }
    end

    --- Splits a string by a single delimeter chosen from the given set.
    -- The first matching delimeter from the set becomes the split character.
    function CmdrUtil.SplitPrioritizedDelimeter(text, delimeters)
        for i, delimeter in ipairs(delimeters) do
            if text:find(delimeter) or i == #delimeters then
                return CmdrUtil.SplitStringSimple(text, delimeter)
            end
        end
    end

    --- Maps values of an array through a callback and returns an array of mapped values
    function CmdrUtil.Map(array, callback)
        local results = {}

        for i, v in ipairs(array) do
            results[i] = callback(v, i)
        end

        return results
    end

    --- Maps arguments #2-n through callback and returns values as tuple
    function CmdrUtil.Each(callback, ...)
        local results = {}
        for i, fuzzyResults in ipairs({ ... }) do
            results[i] = callback(fuzzyResults)
        end
        return unpack(results)
    end

    --- Emulates tabstops with spaces
    function CmdrUtil.EmulateTabstops(text, tabWidth)
        local column = 0
        local textLength = #text
        local result = table.create(textLength)
        for i = 1, textLength do
            local char = string.sub(text, i, i)
            if char == "\t" then
                local spaces = tabWidth - column % tabWidth
                table.insert(result, string.rep(" ", spaces))
                column += spaces
            else
                table.insert(result, char)
                if char == "\n" then
                    column = 0 -- Reset column counter on newlines
                elseif char ~= "\r" then
                    column += 1
                end
            end
        end
        return table.concat(result)
    end

    function CmdrUtil.Mutex()
        local queue = {}
        local locked = false

        return function()
            if locked then
                table.insert(queue, coroutine.running())
                coroutine.yield()
            else
                locked = true
            end

            return function()
                if #queue > 0 then
                    coroutine.resume(table.remove(queue, 1))
                else
                    locked = false
                end
            end
        end
    end
end

return CmdrUtil
