local UIResults = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

function UIResults.display(
    logoId: string,
    values: { { Name: string, Value: any, Icon: string? } },
    stamps: nil?,
    nextCallback: (() -> nil)?
)
    UIController.getStateMachine():Push(UIConstants.States.Results, {
        LogoId = logoId,
        Values = values,
        Stamps = stamps,
        NextCallback = nextCallback,
    })
end

return UIResults
