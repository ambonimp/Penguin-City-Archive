---
-- Macro
---

--------------------------------------------------
-- Dependencies
local Selection = game:GetService("Selection")

--------------------------------------------------
-- Members
local macroDefinition = {
    Name = "Print Item Constants",
    Group = "Character Items",
    Icon = "💡",
    Description = "Prints a group of item's item constants",
    EnableAutomaticUndo = true,
}

macroDefinition.Function = function()
    local selection = Selection:Get()
    if selection[1]:IsA("Folder") then
        selection = selection[1]:GetChildren()
    end

    local function toSnakeCase(str: string)
        local result = ""
        str = str:gsub("_", " "):gsub("%p", "")
        for word in string.gmatch(str, "[%w]+") do
            if not string.find(word, "_") then
                result = result .. (if #result == 0 then "" else "_") .. word:sub(1, 1):upper() .. word:sub(2, #word):lower()
            end
        end

        return result
    end

    for _, shirt in pairs(selection) do
        local name = toSnakeCase(shirt.Name)
        shirt.Name = name
        print(('items["%s"] = {\n\tName = "%s",\n\tPrice = 0,\n\tIcon = nil, --"%s"\n\tForSale = true\n}'):format(name, name, name))
    end
end

return macroDefinition
