local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetUtils = require(ReplicatedStorage.Shared.Pets.PetUtils)

return {
    Name = "addPet",
    Aliases = {},
    Description = "Adds a pet to a player",
    Group = "|petsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add a pet to",
        },
        {
            Type = "petType",
            Name = "petType",
            Description = "petType",
        },
        function(context)
            local petTypeArgument = context:GetArgument(2)
            return PetUtils.getPetVariantCmdrArgument(petTypeArgument)
        end,
        {
            Type = "petRarity",
            Name = "petRarity",
            Description = "petRarity",
        },
        {
            Type = "number",
            Name = "amount",
            Description = "How many to add",
            Default = 1,
        },
    },
}
