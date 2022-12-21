local Players = game:GetService("Players")

return {
    Name = "setWalkSpeed",
    Aliases = {},
    Description = "Sets your walkspeed",
    Group = "|penguinAdmin",
    Args = {
        {
            Type = "number",
            Name = "walkspeed",
            Description = "What walkspeed to set",
        },
    },
    ClientRun = function(_context, walkspeed: number)
        local player = Players.LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = walkspeed
            return ("Your walkspeed was set to %d"):format(walkspeed)
        end

        return "ERROR: Could not get humanoid"
    end,
}
