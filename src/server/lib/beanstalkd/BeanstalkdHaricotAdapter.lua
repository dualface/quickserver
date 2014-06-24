
local haricot = import(".haricot")

local BeanstalkdHaricotAdapter = class("BeanstalkdHaricotAdapter")

function BeanstalkdHaricotAdapter:ctor(easy)
    self.easy = easy
    self.instance = haricot.new(self.easy.config.host, self.easy.config.port)
end

function BeanstalkdHaricotAdapter:connect()
    return true
end

function BeanstalkdHaricotAdapter:close()
    if not self.instance then return false, self.ctorErr end
    return self.instance:quit()
end

function BeanstalkdHaricotAdapter:command(command, ...)
    if not self.instance then return false, self.ctorErr end
    local method = self.instance[command]
    assert(type(method) == "function", string.format("BeanstalkdHaricotAdapter:command() - invalid command %s", tostring(command)))
    local ok, result = method(self.instance, ...)
    if ok then return result end
    return false, result
end

return BeanstalkdHaricotAdapter
