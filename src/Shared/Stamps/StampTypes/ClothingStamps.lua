local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

return {
    {
        Id = "clothing_equip",
        DisplayName = "Stylish",
        Description = "Equip your first clothing item",
        Type = "Clothing",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Stylish,
    },
    -- {
    --     Id = "clothing_twins",
    --     DisplayName = "Twins!",
    --     Description = "Be in the same room as someone with the same outfit + color",
    --     Type = "Clothing",
    --     Difficulty = "Medium",
    --     ImageId = Images.Stamps.Icons.Twins,
    -- },
    {
        Id = "clothing_items25",
        DisplayName = "Full Closet",
        Description = "Own 25 unique clothing items.",
        Type = "Clothing",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.FullCloset,
    },
    {
        Id = "clothing_items100",
        DisplayName = "Hoarder",
        Description = "Own 100 unique clothing items.",
        Type = "Clothing",
        Difficulty = "Hard",
        ImageId = Images.Stamps.Icons.Hoarder,
    },
}
