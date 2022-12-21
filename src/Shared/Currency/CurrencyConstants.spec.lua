local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)

return function()
    local issues: { string } = {}

    -- Enum
    TestUtil.enum(CurrencyConstants.InjectCategory, issues)

    return issues
end
