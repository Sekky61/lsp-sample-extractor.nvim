--[[ this module exposes the interface of lua functions:
define here the lua functions that activate the plugin ]]

local main = require("lsp-sample-extractor.main")

local M = {}

function M.setup(opts)
    local cfg = require("lsp-sample-extractor.config"):set(opts):get()
    return cfg
end

return M
