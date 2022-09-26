local Assume = {}

function Assume.new(validationFunction: () -> (...any))
    local assume = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local isRunning = false
    local isValidationFinished = false

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    assume.validationFunction = validationFunction
    assume.validationResult = {}
    assume.checkerFunction = nil :: (...any) -> boolean
    assume.onCorrect = nil :: (data: any) -> nil
    assume.onWrong = nil :: (data: any) -> nil

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

    -- Sets the function that will be invoked if the assumption was correct (passed all of the validation function's arguments)
    function assume:Then(onCorrect: (data: any) -> nil)
        assertIsRunning()

        assume.onCorrect = onCorrect
        return self
    end

    -- Sets the function that will be invoked if the assumption was wrong (passed all of the validation function's arguments)
    function assume:Else(onWrong: (data: any) -> nil)
        assertIsRunning()

        assume.onWrong = onWrong
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

            local checkerResult = assume.checkerFunction(table.unpack(assume.validationResult))
            if checkerResult then
                if self.onCorrect then
                    self.onCorrect(table.unpack(assume.validationResult))
                end
            else
                if self.onWrong then
                    self.onWrong(table.unpack(assume.validationResult))
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

    return assume
end

return Assume
