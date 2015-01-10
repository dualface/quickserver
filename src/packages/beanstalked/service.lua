local BeanstalkedService = class("BeanstalkedService")

function BeanstalkedService:ctor(config) 
    local beans = require("resty.beanstalkd")
    self.config = config or {host = "127.0.0.1", port = "11300", timeout = 10 * 1000}    

    self.beans = beans:new()
    self.sock = self.beans.sock
    self.connect = rawget(self.class, "connect")
    self.close = rawget(self.class, "close")
    setmetatable(self, {__index=function(table, key) return self.beans[key] end})
end

function BeanstalkedService:connect()
    local beans = self.beans    
    local config = self.config
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end
    
    beans:set_timeout(config.timeout)
    return beans:connect(config.host, config.port)
end

function BeanstalkedService:close()
    local beans = self.beans
    local config = self.config
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    if config.useConnPool then 
        return beans:set_keepalive(10000, 100) 
    end

    return beans:close()
end


return BeanstalkedService
