
local beanstalkd = require("resty.beanstalkd")

local RestyBeanstalkdAdapter = class("RestyBeanstalkdAdapter")

function RestyBeanstalkdAdapter:ctor(easy)
    self.easy = easy
    self.instance, self.ctorErr = beanstalkd:new()
end

function RestyBeanstalkdAdapter:connect()
    if not self.instance then return false, self.ctorErr end

    local _, err = self.instance:connect(self.easy.config.host, self.easy.config.port)
    if err then
        return false, err
    end
    self.instance:set_timeout(self.easy.config.timeout)
    return true
end

function RestyBeanstalkdAdapter:close()
    if not self.instance then return false, self.ctorErr end
    return self.instance:close()
end

function RestyBeanstalkdAdapter:command(command, ...)
    if not self.instance then return false, self.ctorErr end
    local method = self.instance[command]
    assert(type(method) == "function", string.format("RestyBeanstalkdAdapter:command() - invalid command %s", tostring(command)))
    return method(self.instance, ...)
end

return RestyBeanstalkdAdapter
