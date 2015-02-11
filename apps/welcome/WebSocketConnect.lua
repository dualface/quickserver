
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
end

function WebSocketConnect:afterConnectReady()
    -- init
    local tag = self:getSession():get("tag")
    self:setConnectTag(tag)
end

function WebSocketConnect:beforeConnectClose()
    -- cleanup
end

return WebSocketConnect
