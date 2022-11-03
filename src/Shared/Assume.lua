local Assume = {}

function Assume.new(validationFunction: () -> (...any))
    local assume = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local isRunning = false
    local isValidationFinished = false
    local validationFinishedAtTick: number?

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    assume.validationFunction = validationFunction
    assume.validationResult = {}
    assume.checkerFunction = nil :: (...any) -> boolean
    assume.onCorrect = {} :: { (...any) -> nil }
    assume.onWrong = {} :: { (...any) -> nil }

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function assertIsRunning()
        if isRunning then
            error("Assume is already running")
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    --[[
        Checks if validationFunction's returned table.pack(vararg) is good or bad
        - Return true if good.
    ]]
    function assume:Check(checkerFunction: (...any) -> boolean)
        assertIsRunning()

        assume.checkerFunction = checkerFunction
        return self
    end

    -- Adds a function that will be invoked if the assumption was correct (passed all of the validation function's arguments)
    function assume:Then(onCorrect: (...any) -> nil)
        if assume:IsValidationFinished() then
            if assume.checkerFunction(assume:Await()) == true then
                onCorrect(assume:Await())
            end
            return
        end

        table.insert(assume.onCorrect, onCorrect)
        return self
    end

    -- Adds a function that will be invoked if the assumption was wrong (passed all of the validation function's arguments)
    function assume:Else(onWrong: (...any) -> nil)
        if assume:IsValidationFinished() then
            if assume.checkerFunction(assume:Await()) == false then
                onWrong(assume:Await())
            end
            return
        end

        table.insert(assume.onWrong, onWrong)
        return self
    end

    --[[
        Asynchronously runs this assume
        - (Optional): runBefore
        - validationFunction
        - - Correct Assumption: onCorrect
        - - Wrong Assumption: onWrong
    ]]
    function assume:Run(runBefore: (() -> nil)?)
        assertIsRunning()
        isRunning = true

        -- ERROR: No checker
        if not assume.checkerFunction then
            error("No checker function declared!")
        end

        if runBefore then
            runBefore()
        end

        task.spawn(function()
            assume.validationResult = table.pack(self.validationFunction())
            isValidationFinished = true
            validationFinishedAtTick = tick()

            local checkerResult = assume.checkerFunction(table.unpack(assume.validationResult))
            if checkerResult then
                for _, correctCallback in pairs(self.onCorrect) do
                    correctCallback(table.unpack(assume.validationResult))
                end
            else
                for _, wrongCallback in pairs(self.onWrong) do
                    wrongCallback(table.unpack(assume.validationResult))
                end
            end
        end)

        return self
    end

    --[[
        Will return the values returned from the validationFunction (vararg)
        - Yields
    ]]
    function assume:Await(): ...any
        -- ERROR: Not running
        if not isRunning then
            error("Assume is not yet running")
        end

        -- Yield
        while not isValidationFinished do
            task.wait()
        end

        return table.unpack(assume.validationResult)
    end

    --[[
        Has the validation function returned something yet? 
        - `Await()` yields until this returns `true`
    ]]
    function assume:IsValidationFinished()
        return isValidationFinished
    end

    --[[
        Returns how many seconds have passed since the validation finished.
        - Returns `-1` if not yet finished
    ]]
    function assume:GetValidationFinishTimeframe()
        if validationFinishedAtTick then
            return tick() - validationFinishedAtTick
        end

        return -1
    end

    return assume
end

return Assume
