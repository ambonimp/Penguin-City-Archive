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
items.red = {
    Name = "red",
    Price = 1,
}
items.black = {
    Name = "black",
    Price = 1,
}
items.green = {
    Name = "green",
    Price = 1,
}
items.yellow = {
    Name = "yellow",
    Price = 1,
}
items.blue = {
    Name = "blue",
    Price = 1,
}

SnowballToolConstants.Items = items

return SnowballToolConstants
