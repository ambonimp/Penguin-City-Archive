local CharacterConstants = {}

CharacterConstants.WalkSpeed = 20
CharacterConstants.JumpPower = 50

CharacterConstants.Animations = {
    Idle = { { Id = "http://www.roblox.com/asset/?id=10959957667", Weight = 1 } },
    Walk = { { Id = "http://www.roblox.com/asset/?id=10959962833", Weight = 10 } },
    Run = { { Id = "http://www.roblox.com/asset/?id=10964196956", Weight = 10 } },
    Swin = { { Id = "http://www.roblox.com/asset/?id=507784897", Weight = 10 } },
    SwimIdle = { { Id = "http://www.roblox.com/asset/?id=507785072", Weight = 10 } },
    Jump = { { Id = "http://www.roblox.com/asset/?id=10959960325", Weight = 10 } },
    Fall = { { Id = "http://www.roblox.com/asset/?id=507767968", Weight = 10 } },
    Climb = { { Id = "http://www.roblox.com/asset/?id=507765644", Weight = 10 } },
    Sit = { { Id = "rbxassetid://11713388173", Weight = 10 } },
    -- Emotes
    Point = { { Id = "rbxassetid://11713380446", Weight = 11 } },
    Wave = { { Id = "rbxassetid://11713385442", Weight = 11 } },
    Cheer = { { Id = "rbxassetid://11713393646", Weight = 11 }, { Id = "rbxassetid://11713414336", Weight = 11 } },
    -- Tools
    HoldGenericTool = { { Id = "rbxassetid://11762343672", Weight = 14 } },
    UseGenericTool = { { Id = "rbxassetid://11713443688", Weight = 15 } },
    UseSnowballTool = { { Id = "rbxassetid://11713444981", Weight = 15 } },
}

return CharacterConstants
