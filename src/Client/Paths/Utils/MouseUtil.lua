local MouseUtil = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)

local RAYCAST_DEFAULT_LENGTH = 100

function MouseUtil.getMouseTarget(ignore: { Instance }?, ignoresWater: boolean?, length: number?): RaycastResult | nil
    return RaycastUtil.raycastMouse(
        { FilterDescendantsInstances = ignore, FilterType = Enum.RaycastFilterType.Blacklist, IgnoreWater = ignoresWater },
        length or RAYCAST_DEFAULT_LENGTH
    )
end

return MouseUtil
