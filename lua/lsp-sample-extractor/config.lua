local Config = {
    state = {},
    config = {
        debug = true,
    },
}

function Config:set(cfg)
    if cfg then
        self.config = vim.tbl_deep_extend('force', self.config, cfg)
    end
    return self
end

function Config:get()
    return self.config
end

return setmetatable(Config, {
    __index = function(this, k)
        return this.state[k]
    end,
    __newindex = function(this, k, v)
        this.state[k] = v
    end,
})
