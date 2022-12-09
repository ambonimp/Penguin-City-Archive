local Lighting = game:GetService("Lighting")

local function color3FromRGB(color: Color3)
    return ("Color3.fromRGB(%d, %d, %d)"):format(color.R * 255, color.G * 255, color.B * 255)
end

local function number(num: number)
    return ("%d"):format(num)
end

local function decimalNumber(num: number)
    return ("%.3f"):format(num)
end

local function boolean(bool: boolean)
    return bool and "true" or "false"
end

return {
    Name = "Read Lighting Properties",
    Group = "Zones",
    Icon = "💡",
    Description = "Prints out the current Lighting properties to the output window; useful for setting up ZoneSettings",
    Function = function(_macro, plugin)
        -- Read Properties
        local properties: { [string]: string } = {}
        properties.Ambient = color3FromRGB(Lighting.Ambient)
        properties.Brightness = decimalNumber(Lighting.Brightness)
        properties.ColorShift_Bottom = color3FromRGB(Lighting.ColorShift_Bottom)
        properties.ColorShift_Top = color3FromRGB(Lighting.ColorShift_Top)
        properties.EnvironmentDiffuseScale = decimalNumber(Lighting.EnvironmentDiffuseScale)
        properties.EnvironmentSpecularScale = decimalNumber(Lighting.EnvironmentSpecularScale)
        properties.GlobalShadows = boolean(Lighting.GlobalShadows)
        properties.OutdoorAmbient = color3FromRGB(Lighting.OutdoorAmbient)
        properties.ClockTime = decimalNumber(Lighting.ClockTime)
        properties.GeographicLatitude = decimalNumber(Lighting.GeographicLatitude)
        properties.ExposureCompensation = decimalNumber(Lighting.ExposureCompensation)
        properties.FogColor = color3FromRGB(Lighting.FogColor)
        properties.FogEnd = number(Lighting.FogEnd)
        properties.FogStart = number(Lighting.FogStart)

        -- Output
        local str = "\n\nLighting = {"
        for propertyName, propertyValue in pairs(properties) do
            str ..= ("\n    %s = %s,"):format(propertyName, propertyValue)
        end
        str ..= "\n}\n\n"

        print(str)
    end,
}
