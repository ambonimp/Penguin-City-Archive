local PlayerConstants = {}

export type AestheticRoleDetails = {
    Name: string,
    Emoji: string,
    Color: Color3,
}

local aestheticRoleDetails: { [string]: AestheticRoleDetails } = {
    Admin = {
        Name = "Admin",
        Emoji = "🔨",
        Color = Color3.fromRGB(255, 187, 0),
    },
    Tester = {
        Name = "Tester",
        Emoji = "🧪",
        Color = Color3.fromRGB(0, 255, 179),
    },
}
PlayerConstants.AestheticRoleDetails = aestheticRoleDetails

PlayerConstants.Chat = {
    PlayerAttributes = {
        FurColor = "FurColor",
        Role = "Role",
    },
}

return PlayerConstants
