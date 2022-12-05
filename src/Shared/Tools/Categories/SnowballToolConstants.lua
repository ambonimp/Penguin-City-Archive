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
items.red = {
    Id = "red",
    DisplayName = "Red Snowball",
    Price = 1,
}
items.black = {
    Id = "black",
    DisplayName = "Black Snowball",
    Price = 1,
}
items.green = {
    Id = "green",
    DisplayName = "Green Snowball",
    Price = 1,
}
items.yellow = {
    Id = "yellow",
    DisplayName = "Yellow Snowball",
    Price = 1,
}
items.blue = {
    Id = "blue",
    DisplayName = "Blue Snowball",
    Price = 1,
}

SnowballToolConstants.Items = items

return SnowballToolConstants
