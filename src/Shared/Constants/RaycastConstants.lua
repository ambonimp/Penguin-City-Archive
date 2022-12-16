local RaycastConstants = {}

RaycastConstants.Tag = {
    GroundRaycast = "GroundRaycast", -- Used for special parts that wouldn't normally be considered as "ground" in raycasting contexts e.g., pets walking on boardwalk
}

return RaycastConstants
