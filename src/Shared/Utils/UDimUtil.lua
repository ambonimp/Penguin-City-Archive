local UDimUtil = {}

function UDimUtil.multiplyUDim2s(multiplicand: UDim2, multiplier: UDim2): UDim2
    return UDim2.new(
        multiplicand.X.Scale * multiplier.X.Scale,
        multiplicand.X.Offset * multiplier.X.Offset,
        multiplicand.Y.Scale * multiplier.Y.Scale,
        multiplicand.Y.Offset * multiplier.Y.Offset
    )
end

function UDimUtil.scalarMultiplyUDim2(multiplicand: UDim2, multiplier: number): UDim2
    return UDim2.new(
        multiplicand.X.Scale * multiplier,
        multiplicand.X.Offset * multiplier,
        multiplicand.Y.Scale * multiplier,
        multiplicand.Y.Offset * multiplier
    )
end

return UDimUtil
