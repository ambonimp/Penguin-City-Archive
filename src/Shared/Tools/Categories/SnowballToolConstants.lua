local SnowballToolConstants = {}

export type ToolItem = {
    Name: string,
    Price: number,
}

local items: { [string]: ToolItem } = {}
items.Default = {
    Name = "Default",
    Price = 0,
}

SnowballToolConstants.Items = items

return SnowballToolConstants
