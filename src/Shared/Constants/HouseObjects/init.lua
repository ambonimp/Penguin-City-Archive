local HouseObjects = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

for _, module in script:GetChildren() do
    HouseObjects[StringUtil.chopEnd(module.Name, "Constants")] = require(module)
end

return HouseObjects
