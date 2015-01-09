local BeanstalkedService = class("BeanstalkedService")
local beans = require("resty.beanstalkd")

function BeanstalkedService:ctor(config) 
    self.config = config or {host = "127.0.0.1", port = "11300", timeout = 10 * 1000}    

    self.beans = beans:new()

    self.use = self.beans.use
    self.watch = self.beans.watch
    self.ignore = self.beans.ignore
    self.put = self.beans.put
    self.delete = self.beans.delete
    self.reserve = self.beans.reserve
    self.release = self.beans.release
    self.bury = self.beans.bury
    self.kick = self.beans.kick
    self.peek = self.beans.peek
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


rn BeanstalkedService
