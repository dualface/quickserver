
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
end

function WebSocketConnect:afterConnectReady()
    -- send connect id to client
    local connectId = self:getConnectId()
    local message = {connectId = connectId}
    self:sendMessageToSelf(message)

    -- add connect id to online users list
end

function WebSocketConnect:beforeConnectClose()
    -- cleanup
end

return WebSocketConnect
