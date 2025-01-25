local api = require("lsp-sample-extractor.api")
local K = vim.keymap.set

K(
    {'n', 'x'},
    '<Plug>(lsp_sample_get)',
    api.genData(),
    { expr = true, desc = 'Extract code sample' }
)
