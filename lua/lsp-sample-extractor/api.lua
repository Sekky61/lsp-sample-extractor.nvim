local Promise = require("lsp-sample-extractor.promise")
local util = require("lsp-sample-extractor.util")

local function hover_for_position(line, character)
    return Promise.new(function(resolve)
        local params = vim.lsp.util.make_position_params()
        params.position = {
            line = line,
            character = character
        }

        vim.lsp.buf_request_all(0, 'textDocument/hover', params, function(results)
            -- util.log("Got hover " .. vim.inspect(results))
            if results and results[1] and results[1].result then
                resolve(results[1].result)
            else
                resolve(nil)
            end
        end)
    end)
end

local function semantic_tokens_for_position(line, character)
    return Promise.new(function(resolve)
        local tokens = vim.lsp.semantic_tokens.get_at_pos(0, line, character)
        util.log("Got tokens " .. vim.inspect(tokens))
        if tokens then
            resolve(tokens)
        else
            resolve(nil)
        end
    end)
end

local function get_selection_range()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    util.log(vim.inspect(vstart))
    if vstart[2] == 0 then
        return nil
    end
    local line_start = vstart[2] - 1
    local line_end = vend[2] - 1
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

    -- format the content as JSON
    local ok, json_content = pcall(vim.fn.json_encode, content)
    if not ok then
        vim.notify("Failed to encode content as JSON", vim.log.levels.ERROR)
        return
    end

    -- copy JSON to clipboard
    vim.fn.setreg("+", json_content)
    vim.notify("JSON content copied to clipboard!")
end

local api = {}

function api.genData()
    return function()
        util.log("-----")
        util.log("-- Invocation of getData --")
        util.log("-----")
        local mode = vim.fn.mode()
        local hover_promises = {}
        local token_promises = {}

        if mode == 'v' then
            util.log("Visual mode not supported. Did you mean to use visual line mode?")
            return
        elseif mode == 'V' then
            local range = get_selection_range()
            if range == nil then
                util.log("No range selected")
                return
            end
            util.log("Range " .. vim.inspect(range))
            for lineIdx = range[1], range[2] do
                local line = vim.fn.getline(lineIdx)
                local width = string.len(line)
                for char = 0, width do
                    util.log("Dispatch range and sema " .. lineIdx .. " " .. char)
                    table.insert(hover_promises, hover_for_position(lineIdx, char))
                    table.insert(token_promises, semantic_tokens_for_position(lineIdx, char))
                end
            end
        else
            -- Single position hover for normal mode
            local pos = vim.api.nvim_win_get_cursor(0)
            table.insert(hover_promises, hover_for_position(pos[1] - 1, pos[2]))
        end

        local combined_results = {}
        local pending_groups = 2 -- number of promise groups to await

        local function collect_results(key, results)
            combined_results[key] = results
            pending_groups = pending_groups - 1
            if pending_groups == 0 then
                -- all groups have resolved, display combined results
                display_popup(combined_results)
            end
        end

        util.await_collect(hover_promises, { deduplicate = true, destructure = false },
            function(r) collect_results("hover", r) end)
        util.await_collect(token_promises, { deduplicate = true, destructure = true },
            function(r) collect_results("tokens", r) end)
    end
end

return api
