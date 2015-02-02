
local WebSocketServerBase = require("server.base.WebSocketServerBase")

local WebSocketServerApp = class("WebSocketServerApp", WebSocketServerBase)

local OnlineService = cc.load("online").service

function WebSocketServerApp:ctor(config)
    WebSocketServerApp.super.ctor(self, config)

    self.online = OnlineService:create(config.redis)
    ngx.log(ngx.ERR, "WebSocketServerApp:ctor()")
end

function WebSocketServerApp:afterConnectReady()
    -- websocket connection ready
    local session = self:getSession()
    local tag = session:get("tag")
    if not tag then
        throw("invalid tag")
    end
    self:setConnectTag(tag)

    -- save tag into online users list
    self.online:add(tag)
end

function WebSocketServerApp:beforeConnectClose()
    -- remove tag from online users list
    self.online:remove(self:getConnectTag())
end

return WebSocketServerApp
