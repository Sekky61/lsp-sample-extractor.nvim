--[[ this module exposes the interface of lua functions:
define here the lua functions that activate the plugin ]]

local main = require("lsp-sample-extractor.main")

print("Setting up my plugin")

local M = {}

function M.setup(opts)
    print("Running setup")
    local cfg = require("lsp-sample-extractor.config"):set(opts):get()
    local K = vim.keymap.set

    if cfg.gen then
        K({'n', 'x'}, cfg.gen, '<Plug>(lsp_sample_get)', { desc = 'Extract Code Sample' })
    end

    return cfg
end

return M
