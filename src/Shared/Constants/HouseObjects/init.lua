local HouseObjects = {}

for _, module in script:GetChildren() do
    HouseObjects[string.gsub(module.Name, "Constants", "")] = require(module)
end

return HouseObjects
