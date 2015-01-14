local BeanstalkdService = class("BeanstalkdService")

local adapter
if ngx then
    adapter = import(".adapter.RestyBeanstalkdAdapter")
else    
    adapter = import(".adapter.BeanstalkdHaricotAdapter")
end

function BeanstalkdService:ctor(config) 
    if not config or type(config) ~= "table" then 
        return nil, "config is invalid."
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
