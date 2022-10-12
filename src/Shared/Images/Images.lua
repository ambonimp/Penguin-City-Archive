--[[
    Contains all of our Images in the game
     - Use this file to reference an image via code
     - "Register" any image added into the game
     - --!! Ensure you run any images added here through pixel fix!
]]
local Images = {}

--#region ButtonIcons
Images.ButtonIcons = {
    Family = "rbxassetid://11152372064",
    FoldedMap = "rbxassetid://11152371848",
    Igloo = "rbxassetid://11152371425",
    Inventory = "rbxassetid://11152371230",
    Map = "rbxassetid://11152371075",
    Party = "rbxassetid://11152370136",
    StampBook = "rbxassetid://11152369533",
    Toolbox = "rbxassetid://11152369313",
}
--#endregion
--#region Icons
Images.Icons = {
    Add = "rbxassetid://11152372782",
    Badge = "rbxassetid://11152372668",
    Bag = "rbxassetid://11152372582",
    Book = "rbxassetid://11152372490",
    Close = "rbxassetid://11152372397",
    Events = "rbxassetid://11152372332",
    Exit = "rbxassetid://11152372250",
    Face = "rbxassetid://11152372168",
    FloorCarpet = "rbxassetid://11152371963",
    Furniture = "rbxassetid://11152371773",
    Hat = "rbxassetid://11152371685",
    Heart = "rbxassetid://11154920458",
    Igloo = "rbxassetid://11152371572",
    Instructions = "rbxassetid://11152371331",
    Layout = "rbxassetid://11152371133",
    LeftArrow = "rbxassetid://6583639670",
    Message = "rbxassetid://11152371010",
    Minigame = "rbxassetid://11152370898",
    Move = "rbxassetid://11152370757",
    Okay = "rbxassetid://11152370624",
    Outfit = "rbxassetid://11152370509",
    Owner = "rbxassetid://11152370384",
    Paint = "rbxassetid://11152370281",
    PaintBucket = "rbxassetid://11152373133",
    PaintSelected = "rbxassetid://10979216575",
    Pants = "rbxassetid://11152370202",
    Pets = "rbxassetid://11152370072",
    Place = "rbxassetid://11152370003",
    Rotate = "rbxassetid://11152369890",
    RightArrow = "rbxassetid://6583638192",
    Seal = "rbxassetid://11152369785",
    Search = "rbxassetid://11152369702",
    Shirt = "rbxassetid://11152369627",
    Stamp = "rbxassetid://11250982379",
    Text = "rbxassetid://11152369398",
    VoldexLogo = "rbxassetid://11250982454",
    Wallpaper = "rbxassetid://11152369233",
    WindowDoor = "rbxassetid://11152369143",
    Wrench = "rbxassetid://11152369091",
}
--#endregion
--#region Coins
Images.Coins = {
    Bundle1 = "rbxassetid://11152356128",
    Bundle2 = "rbxassetid://11152356045",
    Bundle3 = "rbxassetid://11152355987",
    Bundle4 = "rbxassetid://11152355907",
    Bundle5 = "rbxassetid://11152355811",
    Bundle6 = "rbxassetid://11152355721",
    Coin = "rbxassetid://11152355612",
}
--#endregion
--#region PizzaMinigame
Images.PizzaMinigame = {
    Squid = "rbxassetid://11152398223",
    TomatoSauce = "rbxassetid://11152398287",
    Shrimp = "rbxassetid://11154654667",
    Seaweed = "rbxassetid://11152398463",
    HotSauce = "rbxassetid://11152398581",
    Logo = "rbxassetid://11152398785",
    LogoCartoon = "rbxassetid://11152398954",
    InstructionsPaper = "rbxassetid://11152399041",
    Doodle1 = "rbxassetid://11152399315",
    Doodle2 = "rbxassetid://11152399219",
    Doodle3 = "rbxassetid://11152399111",
    PizzaBase = "rbxassetid://11152399418",
    Cheese = "rbxassetid://11152399496",
    Anchovy = "rbxassetid://11152399621",
}
--#endregion
--#region StampBook
Images.StampBook = {
    Cover = "rbxassetid://11251247354",
    Page = "rbxassetid://11251357764",
    MetalCoil = "rbxassetid://11251357312",
    Seal = "rbxassetid://11251246916",
    PictureFrame = "rbxassetid://11251159219",
    Patterns = {
        Circles = "rbxassetid://11251328139",
        Voldex = "rbxassetid://11251328429",
    },
}
--#endregion

--!! ImageViewer assumes all keys of `Image`s are a table of ImageIds!

return Images
