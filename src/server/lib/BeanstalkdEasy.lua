
local BeanstalkdEasy = class("BeanstalkdEasy")

BeanstalkdEasy.DEFAULT_PRIORITY = 2 ^ 16

local BeanstalkdAdapter
if ngx and ngx.log then
    BeanstalkdAdapter = import(".beanstalkd.RestyBeanstalkdAdapter")
else
    BeanstalkdAdapter = import(".beanstalkd.BeanstalkdHaricotAdapter")
end

function BeanstalkdEasy:ctor(config)
    self.config = clone(totable(config))
    self.config.host = self.config.host or "127.0.0.1"
    self.config.port = self.config.port or 11300
    self.config.timeout = self.config.timeout or 10 * 1000
    self.adapter = BeanstalkdAdapter.new(self)
end

function BeanstalkdEasy:connect()
    return self.adapter:connect()
end

function BeanstalkdEasy:close()
    return self.adapter:close()
end

function BeanstalkdEasy:command(command, ...)
    return self.adapter:command(command, ...)
end

return BeanstalkdEasy
