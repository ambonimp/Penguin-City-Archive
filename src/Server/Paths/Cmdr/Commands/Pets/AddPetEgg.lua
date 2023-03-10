local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetUtils = require(ReplicatedStorage.Shared.Pets.PetUtils)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

return {
    Name = "addPetEgg",
    Aliases = {},
    Description = "Adds a pet egg to a player",
    Group = "|petsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add a pet to",
        },
        {
            Type = "petEgg",
            Name = "petEgg",
            Description = "petEgg",
        },
        {
            Type = "number",
            Name = "hatchTime",
            Description = "How long it takes to hatch",
            Default = PetConstants.DefaultHatchTime,
        },
        {
            Type = "number",
            Name = "amount",
            Description = "How many to add",
            Default = 1,
        },
    },
}
