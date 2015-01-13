local BeanstalkdService = class("BeanstalkdService")

function BeanstalkdService:ctor(config) 
    local adapter
    if ngx then
        adapter = require("adapter.RestyBeanstalkdAdapter")
    else    
        adapter = require("adapter.BeanstalkdHaricotAdapter")
    end

    self.config = config or {host = "127.0.0.1", port = "11300", timeout = 10 * 1000}    

    self.beans = adapter.new(config)
end

function BeanstalkdService:connect()
    local beans = self.beans    
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end
    
    return beans:connect()
end

function BeanstalkdService:close()
    local beans = self.beans
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    return beans:close()
end

function BeanstalkdService:command(command, ...)
    local beans = self.beans
    if not beans then
        return nil, "Package beanstalked is not initialized."
    end

    return beans:command(command, ...)
end

return BeanstalkdService
