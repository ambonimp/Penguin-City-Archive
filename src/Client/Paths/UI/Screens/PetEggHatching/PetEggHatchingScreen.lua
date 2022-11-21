local PetEggHatchingScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TextFilterUtil = require(Paths.Shared.Utils.TextFilterUtil)
local PetsController = require(Paths.Client.Pets.PetsController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local Scope = require(Paths.Shared.Scope)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local UIActions = require(Paths.Client.UI.UIActions)
local Images = require(Paths.Shared.Images.Images)

local TWEEN_TIME = 0.2

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetEggHatching"
screenGui.Enabled = false
screenGui.Parent = Ui

local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Size = UDim2.fromScale(0.7, 0.7)
viewportFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX
viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
viewportFrame.Position = UDim2.fromScale(0.5, 0.5)
viewportFrame.BackgroundTransparency = 1
viewportFrame.Parent = screenGui

local camera = Instance.new("Camera")
camera.Parent = viewportFrame
viewportFrame.CurrentCamera = camera

local openMaid = Maid.new()
local openScope = Scope.new()

local petData: PetConstants.PetData | nil
local petDataIndex: string | nil

function PetEggHatchingScreen.Init()
    -- Register UIState
    do
        local function enter(data: table)
            PetEggHatchingScreen.open(data.PetEggName)
        end

        local function exit()
            PetEggHatchingScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.PetEggHatching, enter, exit)
    end
end

function PetEggHatchingScreen.open(petEggName: string)
    openMaid:Cleanup()

    openScope:NewScope()
    local scopeId = openScope:GetId()

    -- Get Model
    local product = ProductUtil.getPetEggProduct(petEggName)
    local model = ProductUtil.getModel(product)
    if not model then
        error(("Not pet egg %q"):format(petEggName))
    end
    model = model:Clone()
    openMaid:GiveTask(model)

    -- Get Scene
    local scene: Folder = ReplicatedStorage.Assets.Pets.EggHatchingViewportScene
    local eggHitbox: Part = scene.EggHitbox
    local cameraCFrames: { CFrame } = {}

    for i = 1, #scene.Cameras:GetChildren() do
        local cameraModel: Model = scene.Cameras[tostring(i)]
        local lensPart: Part = cameraModel.Lens

        table.insert(cameraCFrames, lensPart.CFrame)
    end

    -- Run it
    model.Parent = viewportFrame
    model:PivotTo(eggHitbox:GetPivot())
    camera.CFrame = cameraCFrames[1]

    task.spawn(function()
        -- Tween Egg
        local sectionTime = PetConstants.PetEggHatchingDuration / (#cameraCFrames - 1)
        for i = 2, #cameraCFrames do
            TweenUtil.tween(camera, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = cameraCFrames[i],
            })
            task.wait(sectionTime)

            -- EXIT: Closed
            if not openScope:Matches(scopeId) then
                return
            end
        end

        -- Wait for PetData
        while not petData do
            task.wait()
        end

        -- Cache as exiting state will clear these values
        local cachedPetData = petData
        local cachedPetDataIndex = petDataIndex

        -- EXIT: Closed
        if not openScope:Matches(scopeId) then
            return
        end

        UIActions.prompt("CONGRATULATIONS", "You just hatched a new pet!", function(parent, maid)
            local petWidget = Widget.diverseWidgetFromPetData(cachedPetData)
            petWidget:Mount(parent, true)
            maid:GiveTask(petWidget)
        end, { Text = "Continue" }, {
            Text = "View Pet",
            Callback = function()
                UIController.getStateMachine():Push(UIConstants.States.PetEditor, {
                    PetData = cachedPetData,
                    PetDataIndex = cachedPetDataIndex,
                })
            end,
        }, { Image = Images.Pets.Lightburst, DoRotate = true })

        UIController.getStateMachine():Remove(UIConstants.States.PetEggHatching)
    end)

    InstanceUtil.fadeIn(viewportFrame, TweenInfo.new(0))
    screenGui.Enabled = true
end

function PetEggHatchingScreen.close()
    petData = nil
    petDataIndex = nil
    openScope:NewScope()

    InstanceUtil.fadeOut(viewportFrame, TweenInfo.new(TWEEN_TIME))
    task.delay(TWEEN_TIME, function()
        screenGui.Enabled = false
    end)
end

function PetEggHatchingScreen:SetHatchedPetData(newPetData: PetConstants.PetData, newPetDataIndex: string)
    petData = newPetData
    petDataIndex = newPetDataIndex
end

return PetEggHatchingScreen
