local SnowballToolConstants = {}
export type ToolItem = {
    Id: string,
    DisplayName: string,
    Price: number,
}

local items: { [string]: ToolItem } = {}
items.Default = {
    Id = "Default",
    DisplayName = "Snowball",
    Price = 0,
}

SnowballToolConstants.Items = items

return SnowballToolConstants
