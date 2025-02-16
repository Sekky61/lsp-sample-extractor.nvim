local M = {}

function M.log(msg)
    local cfg = require("lsp-sample-extractor.config"):get()
    if not cfg.debug then
        return
    end
    print(vim.inspect(msg))
    -- local log_file = vim.fn.stdpath("cache") .. "/nvim_debug.log"
    -- local file = io.open(log_file, "a")
    -- if file then
    --   file:write(vim.fn.strftime("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
    --   file:close()
    -- else
    --   vim.api.nvim_err_writeln("Failed to open debug log file: " .. log_file)
    -- end
end

function M.deep_equal(tbl1, tbl2)
    if tbl1 == tbl2 then return true end
    if type(tbl1) ~= "table" or type(tbl2) ~= "table" then return false end

    for k, v in pairs(tbl1) do
        if not M.deep_equal(v, tbl2[k]) then
            return false
        end
    end

    for k in pairs(tbl2) do
        if tbl1[k] == nil then
            return false
        end
    end

    return true
end

function M.deduplicate_table_array(array)
    local deduplicated = {}
    for _, item in ipairs(array) do
        local is_duplicate = false
        for _, unique_item in ipairs(deduplicated) do
            if M.deep_equal(item, unique_item) then
                is_duplicate = true
                break
            end
        end
        if not is_duplicate then
            table.insert(deduplicated, item)
        end
    end
    return deduplicated
end

function M.insert_unique(array, item)
    for _, existing_item in ipairs(array) do
        if M.deep_equal(existing_item, item) then
            return false -- duplicate, do not insert
        end
    end
    table.insert(array, item)
    return true -- successfully inserted
end

function M.deduplicate(array)
    local r = {}
    for _, item in ipairs(array) do
        M.insert_unique(r, item)
    end
    return r
end

return M
