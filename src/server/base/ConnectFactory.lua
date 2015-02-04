
local ConnectFactory = class("ConnectFactory")

function ConnectFactory.createConnect(config, classNamePrefix)
    local serverAppClass
    if config.appRootPath then
        package.path = config.appRootPath .. "/?.lua;" .. package.path
        local className = classNamePrefix .. "Connect"
        local ok, _serverAppClass = pcall(require, className)
        if ok then
            serverAppClass = _serverAppClass
        else
            local check = string.format("module '%s' not found:", className)
            local err = _serverAppClass
            if string.find(err, check) == nil then
                printWarn("faile to load module \"%s\", %s", className, err)
            end
        end
    end

    if not serverAppClass then
        serverAppClass = require("server.base." .. classNamePrefix .. "ConnectBase")
    end

    return serverAppClass:create(config)
end

return ConnectFactory
