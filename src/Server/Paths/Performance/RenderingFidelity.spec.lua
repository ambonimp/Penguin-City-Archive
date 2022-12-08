local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)

return function()
    local issues: { string } = {}

    local totalFixesNeeded = 0
    DescendantLooper.workspace(function(instance)
        return instance:IsA("MeshPart")
    end, function(meshPart: MeshPart)
        if meshPart.RenderFidelity ~= Enum.RenderFidelity.Performance then
            totalFixesNeeded += 1
        end
    end, true)

    if totalFixesNeeded > 0 then
        table.insert(
            issues,
            ("%d MeshParts found with non-Performance Rendering Fidelity. Run the Fix Rendering Fidelity macro to fix this."):format(
                totalFixesNeeded
            )
        )
    end

    return issues
end
