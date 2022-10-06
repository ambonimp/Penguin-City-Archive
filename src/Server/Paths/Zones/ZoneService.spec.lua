return function()
    local issues: { string } = {}

    -- Streaming
    do
        -- Must be enabled
        if not game.Workspace.StreamingEnabled then
            table.insert(issues, "StreamingEnabled is StreamingDisabled! Set that to true")
        end
    end

    return issues
end
