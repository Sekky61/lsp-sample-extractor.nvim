local util = require("lsp-sample-extractor.util")
local async = require "plenary.async"

-- Async
local function hover_for_position(line, character)
    local params = vim.lsp.util.make_position_params()
    params.position = {
        line = line,
        character = character
    }

    local res, err = async.lsp.buf_request_all(0, 'textDocument/hover', params)
    assert(not err, err)
    if res and res[1] and res[1].result then
        return res[1].result
    else
        return nil
    end
end

local function semantic_tokens_for_position(line, character)
    local tokens = vim.lsp.semantic_tokens.get_at_pos(0, line, character)
    if tokens then
        return tokens
    else
        return nil
    end
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
        line_end
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
        util.log("-----")
        util.log("-- Invocation of getData --")
        util.log("-----")
        local mode = vim.fn.mode()
        local hovers = {}
        local tokens = {}

        local range = get_selection_line_range()
        if range == nil then
            util.log("No range selected")
            return
        end
        local startLine = range[1]
        local endLine = range[2]

        if mode == 'v' then
            util.log("Visual mode not supported. Did you mean to use visual line mode?")
            return
        elseif mode == 'V' then
            for lineIdx = startLine, endLine do
                local line = vim.fn.getline(lineIdx + 1)
                local width = string.len(line)
                print("Line length", width)
                for char = 0, width do
                    table.insert(hovers, hover_for_position(lineIdx, char))
                    table.insert(tokens, semantic_tokens_for_position(lineIdx, char))
                end
            end
        else
            -- Single position hover for normal mode
            local pos = vim.api.nvim_win_get_cursor(0)
            table.insert(hovers, hover_for_position(pos[1] - 1, pos[2]))
        end

        local lines = vim.api.nvim_buf_get_lines(0, startLine, endLine, false)
        local code = table.concat(lines, "\n")

        local combined_results = {
            version = "1",
            code = code,
            range = range,
            hover = util.deduplicate(hovers),
            tokens = util.deduplicate(tokens)
        }
        display_popup(combined_results)
    end
    return function()
        async.run(f, nil)
    end
end

return api
