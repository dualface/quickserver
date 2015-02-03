
local ConnectFactory = class("ConnectFactory")

function ConnectFactory.createConnect(config, classNamePrefix)
    local serverAppClass
    if config.appRootPath then
        package.path = config.appRootPath .. "/?.lua;" .. package.path
        local className = classNamePrefix .. "Connect"
        local ok, _serverAppClass = pcall(require, className)
        if ok then
            serverAppClass = _serverAppClass
        end
    end

    if not serverAppClass then
        serverAppClass = require("server.base." .. classNamePrefix .. "ConnectBase")
    end

    return serverAppClass:create(config)
end

return ConnectFactory
