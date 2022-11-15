local UIActions = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Maid = require(Paths.Packages.maid)
local Queue = require(Paths.Shared.Queue)

-- Pulls up the results screen via a uiStateMachine push
function UIActions.displayResults(
    logoId: string,
    values: { { Name: string, Value: any, Icon: string? } },
    nextCallback: (() -> nil)?,
    stampData: { [string]: number }?
)
    UIController.getStateMachine():Push(UIConstants.States.Results, {
        LogoId = logoId,
        Values = values,
        NextCallback = nextCallback,
        StampData = stampData,
    })
end

function UIActions.prompt(
    title: string?,
    description: string?,
    middleMounter: ((parent: GuiObject, maid: typeof(Maid.new())) -> nil)?,
    leftButton: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }?,
    rightButton: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }?,
    background: { Blur: boolean?, Image: string? }?
)
    Queue.addTask(UIActions, function()
        UIController.getStateMachine():Push(UIConstants.States.GenericPrompt, {
            Title = title,
            Description = description,
            MiddleMounter = middleMounter,
            LeftButton = leftButton,
            RightButton = rightButton,
            Background = background,
        })

        while UIController.getStateMachine():HasState(UIConstants.States.GenericPrompt) do
            task.wait()
        end
    end)
end

return UIActions
