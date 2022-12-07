local SnowballToolConstants = {}
export type ToolItem = {
    Id: string,
    DisplayName: string,
    Price: number,
}

local items: { [string]: ToolItem } = {}
items.CoffeeCup = {
    Id = "CoffeeCup",
    DisplayName = "Coffee Cup",
    Price = 0,
}
items.TakeawayCup = {
    Id = "TakeawayCup",
    DisplayName = "Takeaway Cup",
    Price = 0,
}
items.Donut = {
    Id = "Donut",
    DisplayName = "Donut",
    Price = 0,
}
items.Medkit = {
    Id = "Medkit",
    DisplayName = "Medkit",
    Price = 0,
}
items.Pizza = {
    Id = "Pizza",
    DisplayName = "Pizza",
    Price = 0,
}

SnowballToolConstants.Items = items

return SnowballToolConstants
