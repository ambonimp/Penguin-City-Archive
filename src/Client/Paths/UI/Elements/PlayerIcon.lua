local PlayerIcon = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local Promise = require(Paths.Packages.promise)
local DataController = require(Paths.Client.DataController)
local DataUtil = require(Paths.Shared.Utils.DataUtil)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)

local CHARACTER_HIDE_POSITION = Vector3.new(0, 50000, 0)
local CAMERA_POSITION_OFFSET = Vector3.new(0, 2, -3)
local CAMERA_LOOK_OFFSET = Vector3.new(0, 2, 0)

function PlayerIcon.new(playerOrUserId: Player | number)
    local playerIcon = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromScale(1, 1)

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function viewport(player: Player)
        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Size = UDim2.fromScale(1, 1)
        viewportFrame.Parent = frame

        local camera = Instance.new("Camera")
        viewportFrame.CurrentCamera = camera
        camera.Parent = viewportFrame

        local character: Model = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
        character:PivotTo(character:GetPivot() - character:GetPivot().Position + CHARACTER_HIDE_POSITION)
        character.Parent = viewportFrame

        -- Camera Position
        local humanoidRootPart: MeshPart = character.HumanoidRootPart
        camera.CFrame = CFrame.new(humanoidRootPart.Position + CAMERA_POSITION_OFFSET, humanoidRootPart.Position + CAMERA_LOOK_OFFSET)

        local dataPromise = Promise.new(function(resolve, _reject, _onCancel)
            local characterAppearance = DataUtil.readAsArray(DataController.getPlayer(player, "CharacterAppearance"))
            resolve(characterAppearance)
        end):andThen(function(characterAppearance: CharacterItems.Appearance)
            -- Apply to a clone character that we can place in workspace so RigidConstraints in `applyAppearance` will work
            local prettyCharacter: Model = character:Clone()
            prettyCharacter.Parent = game.Workspace
            CharacterUtil.applyAppearance(prettyCharacter, characterAppearance)
            task.wait() -- Wait a frame for RigidConstraints to work
            prettyCharacter.Parent = viewportFrame
            character:Destroy()

            -- Remove Character eyelids so we can see those lovely eyes!
            prettyCharacter.EyeLids:Destroy()
        end)
        playerIcon:GetMaid():GiveTask(function()
            dataPromise:cancel()
        end)
    end

    local function thumbnail(userId: number)
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.BackgroundTransparency = 1
        imageLabel.Size = UDim2.fromScale(1, 1)
        imageLabel.Image = ""
        imageLabel.Parent = frame

        task.spawn(function()
            imageLabel.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function playerIcon:Mount(parent: GuiObject, hideParent: boolean?)
        frame.Parent = parent

        if hideParent then
            parent.BackgroundTransparency = 1
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Create viewport/thumbnail
    local player = (typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") and playerOrUserId)
        or Players:GetPlayerByUserId(tonumber(playerOrUserId) or 0)
    if player then
        viewport(player)
    else
        thumbnail(tonumber(playerOrUserId) or 0)
    end

    playerIcon:GetMaid():GiveTask(frame)

    return playerIcon
end

return PlayerIcon
