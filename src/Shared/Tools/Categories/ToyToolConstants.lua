local ToyToolConstants = {}
export type ToolItem = {
    Id: string,
    DisplayName: string,
    Price: number,
    Rotation: CFrame?,
}

local items: { [string]: ToolItem } = {}

items.Medkit = {
    Id = "Medkit",
    DisplayName = "Medkit",
    Price = 0,
}
items.Balloons = {
    Id = "Balloons",
    DisplayName = "Balloons",
    Price = 0,
}
items.Book = {
    Id = "Book",
    DisplayName = "Book",
    Price = 0,
}
items.Notebook = {
    Id = "Notebook",
    DisplayName = "Notebook",
    Price = 0,
}

ToyToolConstants.Items = items

return ToyToolConstants
