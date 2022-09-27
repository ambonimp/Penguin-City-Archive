local CharacterItems = {}

for _, module in script:GetChildren() do
    CharacterItems[string.gsub(module.Name, "Constants", "")] = require(module)
end

return CharacterItems
