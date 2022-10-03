local DeviceUtil = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

function DeviceUtil.getDeviceType(): "Console" | "Mobile" | "Desktop"
    if GuiService:IsTenFootInterface() then
        return "Console"
    elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return "Mobile"
    else
        return "Desktop"
    end
end

function DeviceUtil.isMobile()
    return DeviceUtil.getDeviceType() == "Mobile"
end

function DeviceUtil.isConsole()
    return DeviceUtil.getDeviceType() == "Console"
end

function DeviceUtil.isDesktop()
    return DeviceUtil.getDeviceType() == "Desktop"
end

return DeviceUtil
