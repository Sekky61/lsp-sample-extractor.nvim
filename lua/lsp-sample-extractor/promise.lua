local Promise = {}
Promise.__index = Promise

function Promise.new(executor)
    local self = setmetatable({}, Promise)
    self.status = "pending"
    self.value = nil
    self.callbacks = {}
    
    local function resolve(value)
        if self.status == "pending" then
            self.status = "fulfilled"
            self.value = value
            for _, callback in ipairs(self.callbacks) do
                callback(value)
            end
        end
    end
    
    executor(resolve)
    return self
end

function Promise:th(callback)
    if self.status == "fulfilled" then
        callback(self.value)
    else
        table.insert(self.callbacks, callback)
    end
    return self
end

return Promise
