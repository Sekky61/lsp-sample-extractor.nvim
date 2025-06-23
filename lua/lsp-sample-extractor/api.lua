local util = require("lsp-sample-extractor.util")
local async = require("plenary.async")

-- Async
local function hover_for_position(line, character)
    local params = vim.lsp.util.make_position_params()
    params.position = {
        line = line,
        character = character,
    }

    local res = async.lsp.buf_request_all(0, "textDocument/hover", params)
    if res then
        -- buf_request_all returns client_id:result map
        for client_id, client_result in pairs(res) do
            if client_result and client_result.result then
                local hover_result = client_result.result
                if hover_result and hover_result.contents then
                    -- Add position info to the hover result if not present
                    if not hover_result.range then
                        hover_result.range = {
                            start = { line = line, character = character },
                            ["end"] = { line = line, character = character }
                        }
                    end
                    util.log("Found hover at line " .. line .. ", col " .. character)
                    return hover_result
                end
            end
        end
    end
    return nil
end

local function get_semantic_tokens_in_range(start_line, end_line)
    local tokens = {}
    local seen_tokens = {}

    util.log("Collecting semantic tokens from line " .. start_line .. " to " .. end_line)
    
    for line = start_line, end_line - 1 do
        local line_content = vim.fn.getline(line + 1)
        local line_length = string.len(line_content)
        
        util.log("Processing line " .. line .. " with length " .. line_length)
        
        -- Sample key positions: word boundaries, operators, etc.
        local positions_to_check = {}
        
        -- Always check start of line if not empty
        if line_length > 0 then
            table.insert(positions_to_check, 0)
        end
        
        -- Find word boundaries and special characters
        for col = 0, line_length - 1 do
            local char = line_content:sub(col + 1, col + 1)
            local prev_char = col > 0 and line_content:sub(col, col) or " "
            
            -- Check at word boundaries or special characters
            if char:match("[%w_]") and not prev_char:match("[%w_]") then
                table.insert(positions_to_check, col)
            elseif char:match("[%.%(%):;,{}%[%]]") then
                table.insert(positions_to_check, col)
            end
        end
        
        -- Check tokens at strategic positions
        for _, col in ipairs(positions_to_check) do
            local pos_tokens = vim.lsp.semantic_tokens.get_at_pos(0, line, col)
            if pos_tokens then
                for _, token in ipairs(pos_tokens) do
                    -- Only include tokens within our range and avoid duplicates
                    if token.line >= start_line and token.line < end_line then
                        local token_key = token.line .. ":" .. token.start_col .. ":" .. token.end_col .. ":" .. token.type
                        if not seen_tokens[token_key] then
                            seen_tokens[token_key] = true
                            table.insert(tokens, token)
                        end
                    end
                end
            end
        end
    end

    util.log("Found " .. #tokens .. " semantic tokens")
    return tokens
end

--- Returns the zero-based, end exclusive index of the lines of the current selection.
---
--- @return table|nil A table containing the start and end line indices, or nil if no selection is active.
local function get_selection_line_range()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    if vstart[2] == 0 then
        return nil
    end
    local line_start = vstart[2] - 1
    local line_end = vend[2]
    return {
        line_start,
        line_end,
    }
end

local function display_popup(content)
    if type(content) ~= "table" then
        vim.notify("display_popup: content must be a table", vim.log.levels.ERROR)
        return
    end

    local ok, json_content = pcall(vim.json.encode, content)
    if not ok then
        vim.notify("Failed to encode content as JSON", vim.log.levels.ERROR)
        return
    end

    vim.fn.setreg("+", json_content)
    vim.notify("JSON content copied to clipboard")
end

local api = {}

function api.genData()
    local f = function()
        vim.notify("Extracting LSP data...", vim.log.levels.INFO)
        util.log("-----")
        util.log("-- Invocation of getData --")
        util.log("-----")

        -- Check if LSP clients are available
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
            vim.notify("No LSP clients attached to current buffer", vim.log.levels.WARN)
            return
        end

        local mode = vim.fn.mode()
        local hovers = {}
        local tokens = {}

        local range = get_selection_line_range()
        if range == nil then
            util.log("No range selected")
            vim.notify("No selection found. Please select lines in visual mode.", vim.log.levels.WARN)
            return
        end
        local startLine = range[1]
        local endLine = range[2]

        if mode == "v" then
            util.log("Visual mode not supported. Did you mean to use visual line mode?")
            vim.notify("Visual character mode not supported. Please use visual line mode (Shift+V)", vim.log.levels.WARN)
            return
        elseif mode == "V" then
            -- Get semantic tokens for the entire range efficiently
            local range_tokens = get_semantic_tokens_in_range(startLine, endLine)
            for _, token in ipairs(range_tokens) do
                table.insert(tokens, token)
            end

            -- Get hover info for strategic positions where tokens exist
            for lineIdx = startLine, endLine - 1 do
                local line = vim.fn.getline(lineIdx + 1)
                local width = string.len(line)
                util.log("Processing hover for line " .. lineIdx .. " with length " .. width)

                -- Get positions where semantic tokens exist
                local token_positions = {}
                for col = 0, width - 1 do
                    local pos_tokens = vim.lsp.semantic_tokens.get_at_pos(0, lineIdx, col)
                    if pos_tokens and #pos_tokens > 0 then
                        table.insert(token_positions, col)
                    end
                end
                
                -- Remove duplicate positions and get hover for unique positions
                local unique_positions = {}
                for _, pos in ipairs(token_positions) do
                    unique_positions[pos] = true
                end
                
                for pos, _ in pairs(unique_positions) do
                    local hover_result = hover_for_position(lineIdx, pos)
                    if hover_result then
                        table.insert(hovers, hover_result)
                    end
                end
            end
        else
            -- Single position hover for normal mode
            local pos = vim.api.nvim_win_get_cursor(0)
            local hover_result = hover_for_position(pos[1] - 1, pos[2])
            if hover_result then
                table.insert(hovers, hover_result)
            end
        end

        local lines = vim.api.nvim_buf_get_lines(0, startLine, endLine, false)
        local code = table.concat(lines, "\n")

        local combined_results = {
            version = "1",
            code = code,
            range = range,
            hover = util.deduplicate(hovers),
            tokens = util.deduplicate(tokens),
        }

        util.log("Collected " .. #hovers .. " hover entries and " .. #tokens .. " tokens")
        display_popup(combined_results)
    end
    return function()
        async.run(function()
            local ok, err = pcall(f)
            if not ok then
                vim.notify("Error extracting LSP data: " .. tostring(err), vim.log.levels.ERROR)
                util.log("Function error: " .. tostring(err))
            end
        end, function(async_err)
            if async_err then
                vim.notify("Async error: " .. vim.inspect(async_err), vim.log.levels.ERROR)
                util.log("Async error: " .. vim.inspect(async_err))
            end
        end)
    end
end

return api
