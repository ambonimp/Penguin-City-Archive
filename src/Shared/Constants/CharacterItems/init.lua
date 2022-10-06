local CharacterItems = {}
export type Appearance = { [string]: { string }? }

for _, module in script:GetChildren() do
    CharacterItems[string.gsub(module.Name, "Constants", "")] = require(module)
end

return CharacterItems
