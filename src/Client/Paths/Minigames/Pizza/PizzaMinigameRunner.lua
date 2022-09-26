local PizzaMinigameRunner = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local RaycastUtil = require(Paths.Shared.Utils.RaycastUtil)

local RAYCAST_LENGTH = 100

local runMaid = Maid.new()
local minigameFolder: Folder?
local currentHitbox: BasePart | nil
local hitboxParts: { BasePart } = {}

-------------------------------------------------------------------------------
-- Run / Stop
-------------------------------------------------------------------------------

function PizzaMinigameRunner.run(newMinigameFolder: Folder)
    minigameFolder = newMinigameFolder

    -- Init runner
    do
        -- HitboxParts
        for _, descendant in pairs(minigameFolder.Hitboxes:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(hitboxParts, descendant)
            end
        end
    end

    -- Setup Frame Updates
    runMaid:GiveTask(RunService.RenderStepped:Connect(function(dt)
        PizzaMinigameRunner.tick(dt)
    end))
end

function PizzaMinigameRunner.stop()
    runMaid:Cleanup()

    minigameFolder = nil
    currentHitbox = nil
    hitboxParts = {}
end

-------------------------------------------------------------------------------
-- Frame Updates
-------------------------------------------------------------------------------

function PizzaMinigameRunner.tick(_dt)
    -- Hitbox
    local raycastResult = RaycastUtil.raycastMouse({
        FilterDescendantsInstances = hitboxParts,
        FilterType = Enum.RaycastFilterType.Whitelist,
    }, RAYCAST_LENGTH)
    currentHitbox = raycastResult and raycastResult.Instance

    print("current hitbox:", currentHitbox)
end

return PizzaMinigameRunner
