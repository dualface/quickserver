
local ServerFactory = class("ServerFactory")

function ServerFactory.createApp(config, classNamePrefix)
    dump(config)
    local serverAppClass
    if config.appRootPath then
        package.path = config.appRootPath .. "/?.lua;" .. package.path
        local className = classNamePrefix .. "ServerApp"
        local ok, _serverAppClass = pcall(require, className)
        if ok then
            serverAppClass = _serverAppClass
        end
    end

    if not serverAppClass then
        serverAppClass = require("server.base." .. classNamePrefix .. "ServerBase")
    end

    return serverAppClass:create(config)
end

return ServerFactory
