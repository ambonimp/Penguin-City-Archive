--[[
    Runs unit tests
    ]]
local UnitTester = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

-- Constants
local GOOD = "🟩"
local BAD = "🟥"
local UNIT_TEST_SUFFIX = ".spec"

--[[
    Finds and runs all the tests in UnitTests.

    Returns our findings.
]]
function UnitTester.Run(directory: Instance)
    -- Gather test scripts
    local testScripts: { ModuleScript } = {}
    for _, descendant in pairs(directory:GetDescendants()) do
        if descendant:IsA("ModuleScript") and StringUtil.endsWith(descendant.Name, UNIT_TEST_SUFFIX) then
            table.insert(testScripts, descendant)
        end
    end
    local totalTests = #testScripts

    -- Run Tests + track findings
    local findings: { [ModuleScript]: { string } } = {}
    local totalTestsPassed = 0
    for _, testScript in pairs(testScripts) do
        -- Be sure to catch errors here too
        local requireSuccess, requireResult = pcall(require, testScript)
        local testFindings: { string } = {}

        if requireSuccess then
            -- ERROR: Not a function
            local testFunction = requireResult
            if typeof(testFunction) ~= "function" then
                error((".test %s does not return a function!"):format(testScript:GetFullName()))
            end

            local testFindingsSucess, testFindingsResult = pcall(function()
                return testFunction()
            end)
            if testFindingsSucess then
                if typeof(testFindingsResult) == "table" then
                    testFindings = testFindingsResult
                else
                    testFindings = {
                        ("RunTest returned %s (%s). Expected type {string}"):format(
                            tostring(testFindingsResult),
                            typeof(testFindingsResult)
                        ),
                    }
                end
            else
                testFindings = { tostring(testFindingsResult) } -- Wrap error message in table
            end
        else
            testFindings = { requireResult } -- Wrap error message in table
        end

        -- Cache results
        findings[testScript] = testFindings
        totalTestsPassed += (#testFindings == 0 and 1 or 0)
    end

    -- Feedback
    local passedWithFlyingColours = totalTestsPassed == totalTests
    local location = RunService:IsServer() and "SERVER" or "CLIENT"
    local resultColor = passedWithFlyingColours and GOOD or BAD
    local outputMethod = passedWithFlyingColours and print or warn
    outputMethod(("> UNIT TESTER (%s)"):format(location))
    outputMethod(("  > %s PASSED %d/%d TESTS"):format(resultColor, totalTestsPassed, totalTests))

    -- EXIT: Passed!
    if passedWithFlyingColours then
        return
    end

    -- FAILED :c Show error emssages
    for testScript, testFindings in pairs(findings) do
        -- Create error message if this testScript caused errors
        if #testFindings > 0 then
            outputMethod(("    > %s"):format(testScript.Name))
            for i, issue in ipairs(testFindings) do
                outputMethod(("      (%d) %s"):format(i, issue))
            end
        end
    end
end

return UnitTester
